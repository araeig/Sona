import json

import numpy as np
from joblib import dump
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import GroupKFold, GroupShuffleSplit
from sklearn.multiclass import OneVsRestClassifier

from services.clap_service import ClapService

DATASET_PATH = "data/mood_dataset.jsonl"
MODEL_PATH = "data/mood_classifier.joblib"
MOODS = [
    "calm", "energetic", "happy", "sad", "dark",
    "romantic", "dreamy", "aggressive", "epic", "groovy",
]
C_VALUES = [0.1, 1.0, 10.0]


def precision_at_1(scores, labels):
    top = np.argmax(scores, axis=1)
    return labels[np.arange(len(labels)), top].mean()


def make_model(c):
    return OneVsRestClassifier(
        LogisticRegression(C=c, max_iter=2000, class_weight="balanced")
    )


with open(DATASET_PATH, encoding="utf-8") as file:
    rows = [json.loads(line) for line in file]

X = np.array([row["embedding"] for row in rows])
Y = np.array([[1 if mood in row["moods"] else 0 for mood in MOODS] for row in rows])
groups = np.array([row["artist_id"] for row in rows])

splitter = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
train_idx, test_idx = next(splitter.split(X, Y, groups))
X_train, Y_train, groups_train = X[train_idx], Y[train_idx], groups[train_idx]
X_test, Y_test = X[test_idx], Y[test_idx]
print(f"Train: {len(train_idx)} tracks, {len(set(groups_train))} artists")
print(f"Test:  {len(test_idx)} tracks, {len(set(groups[test_idx]))} artists\n")

best_c, best_score = None, -1.0
for c in C_VALUES:
    fold_scores = []
    for fold_train, fold_val in GroupKFold(n_splits=5).split(X_train, Y_train, groups_train):
        model = make_model(c).fit(X_train[fold_train], Y_train[fold_train])
        fold_scores.append(precision_at_1(model.predict_proba(X_train[fold_val]), Y_train[fold_val]))
    score = float(np.mean(fold_scores))
    print(f"C={c:<5} cross-validation precision@1: {100 * score:.0f}%")
    if score > best_score:
        best_c, best_score = c, score
print(f"Best C: {best_c}\n")

model = make_model(best_c).fit(X_train, Y_train)
trained_scores = model.predict_proba(X_test)

clap = ClapService()
text_vectors = np.array([clap.embed_text(f"This is {mood} music.") for mood in MOODS])
zero_shot_scores = X_test @ text_vectors.T - (X_train @ text_vectors.T).mean(axis=0)

most_common = int(np.argmax(Y_train.sum(axis=0)))
random_score = Y_test.sum(axis=1).mean() / len(MOODS)

print("Precision@1 on test set:")
print(f"  random choice        {100 * random_score:.0f}%")
print(f"  always '{MOODS[most_common]}'   {100 * Y_test[:, most_common].mean():.0f}%")
print(f"  zero-shot (phrases)  {100 * precision_at_1(zero_shot_scores, Y_test):.0f}%")
print(f"  trained classifier   {100 * precision_at_1(trained_scores, Y_test):.0f}%")

def per_track_ranks(scores):
    return scores.argsort(axis=1).argsort(axis=1)


ensemble_scores = per_track_ranks(zero_shot_scores) + per_track_ranks(trained_scores)
print(f"  zero-shot + trained  {100 * precision_at_1(ensemble_scores, Y_test):.0f}%")

print("\nPer mood (trained, threshold 0.5):")
predicted = (trained_scores >= 0.5).astype(int)
print(classification_report(Y_test, predicted, target_names=MOODS, zero_division=0))

final_model = make_model(best_c).fit(X, Y)
dump({"model": final_model, "moods": MOODS}, MODEL_PATH)
print(f"Saved final model (trained on all {len(rows)} tracks) to {MODEL_PATH}")
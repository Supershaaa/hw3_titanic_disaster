import sys
import pathlib
import pandas as pd
import numpy as np

from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score

def loud(msg):
    print(f"[INFO] {msg}", flush=True)

# Resolve repo-relative paths: this file is in src/app/
HERE = pathlib.Path(__file__).resolve()
ROOT = HERE.parents[2]                 # repo root
DATA_DIR = ROOT / "src" / "data"
OUT_DIR  = pathlib.Path("/app/out")  #OUT_DIR  = ROOT / "src" / "output"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# --- Load data
train_path = DATA_DIR / "train.csv"
test_path  = DATA_DIR / "test.csv"

train = pd.read_csv(train_path)
test  = pd.read_csv(test_path)

loud(f"train dataset shape: {train.shape}")
loud(f"train dataset columns: {list(train.columns)}")
loud(f"test dataset shape: {test.shape}")
loud(f"test dataset columns: {list(test.columns)}")

def add_title_feature(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    if "Name" in df.columns:
        loud("Engineering feature: Title extracted from Name")
        df["Title"] = (
            df["Name"]
              .str.extract(r",\s*([^\.]+)\.")
              .iloc[:, 0]
              .replace({
                  "Mlle": "Miss", "Ms": "Miss", "Mme": "Mrs",
                  "Lady": "Noble", "Countess": "Noble", "Sir": "Noble",
                  "Dona": "Noble", "Don": "Noble", "Jonkheer": "Noble",
                  "Capt": "Officer", "Col": "Officer", "Major": "Officer",
                  "Dr": "Officer", "Rev": "Clergy"
              })
              .fillna("Unknown")
        )
    else:
        df["Title"] = "Unknown"

    loud("Engineering feature: FamilySize = SibSp + Parch + 1")
    df["FamilySize"] = df.get("SibSp", 0) + df.get("Parch", 0) + 1

    loud("Engineering feature: IsAlone = 1 if FamilySize==1 else 0")
    df["IsAlone"] = (df["FamilySize"] == 1).astype(int)

    loud("Engineering feature: CabinKnown = 1 if Cabin not null")
    df["CabinKnown"] = (~df.get("Cabin").isna()).astype(int)

    loud("Engineering feature: Deck = first letter of Cabin (U if missing)")
    df["Deck"] = df.get("Cabin").apply(lambda x: x[0] if pd.notna(x) else "U")

    loud("Engineering feature: Fare_log = log1p(Fare) with median fill")
    fare_med = df["Fare"].median() if "Fare" in df.columns else 0.0
    df["Fare_log"] = np.log1p(df.get("Fare", 0).fillna(fare_med))

    return df

def select_features(df: pd.DataFrame) -> pd.DataFrame:
    keep = [
        "Survived",          # may not exist in test
        "Pclass","Sex","Age","SibSp","Parch",
        "Fare_log","Embarked",
        "Title","FamilySize","IsAlone","CabinKnown","Deck"
    ]
    cols = [c for c in keep if c in df.columns]
    return df[cols].copy()

def build_pipeline(numeric_features, categorical_features):
    loud("Building preprocessing + logistic regression pipeline")
    numeric_pipe = Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
    ])
    categorical_pipe = Pipeline([
        ("imputer", SimpleImputer(strategy="most_frequent")),
        ("ohe", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
    ])

    preprocessor = ColumnTransformer([
        ("num", numeric_pipe, numeric_features),
        ("cat", categorical_pipe, categorical_features),
    ])

    clf = LogisticRegression(max_iter=200, solver="liblinear")
    return Pipeline([("prep", preprocessor), ("clf", clf)])

# --- Feature engineering
train_add = add_title_feature(train)
test_add  = add_title_feature(test)

train_sel = select_features(train_add)
test_sel  = select_features(test_add)

loud("Preview of engineered training features (head):")
loud(train_sel.head().to_string())

# --- Split X/y
if "Survived" not in train_sel.columns:
    loud("ERROR: train.csv is missing 'Survived' column.")
    sys.exit(1)

y_train = train_sel["Survived"].astype(int)
X_train = train_sel.drop(columns=["Survived"])

# feature types
numeric_features = [c for c in X_train.columns if X_train[c].dtype != "object"]
categorical_features = [c for c in X_train.columns if X_train[c].dtype == "object"]

loud(f"Numeric features: {numeric_features}")
loud(f"Categorical features: {categorical_features}")

# --- Train
pipe = build_pipeline(numeric_features, categorical_features)

loud("Fitting logistic regression on training set…")
pipe.fit(X_train, y_train)
loud("Done fitting.")

# --- Train accuracy
yhat_train = pipe.predict(X_train)
train_acc = accuracy_score(y_train, yhat_train)
loud(f"Training accuracy: {train_acc:.4f}")

# --- Test predictions + optional test accuracy
has_test_y = "Survived" in test_sel.columns
X_test = test_sel.drop(columns=["Survived"]) if has_test_y else test_sel

loud("Predicting on test set…")
test_pred = pipe.predict(X_test)

if has_test_y:
    test_acc = accuracy_score(test_sel["Survived"].astype(int), test_pred)
    loud(f"Test accuracy: {test_acc:.4f}")
else:
    loud("No 'Survived' in test.csv — skipping test accuracy (Kaggle-style test).")

# --- Save predictions
out = pd.DataFrame({"PredSurvived": test_pred})
if "PassengerId" in test.columns:
    out.insert(0, "PassengerId", test["PassengerId"])

out_path = OUT_DIR / "predictions.csv"
out.to_csv(out_path, index=False)
loud(f"Saved predictions to: {out_path}")
loud("Pipeline completed successfully.")

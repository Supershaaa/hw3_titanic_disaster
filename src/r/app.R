# src/r/app.R
suppressPackageStartupMessages({
  library(data.table)
  library(stringr)
})

loud <- function(msg) cat(sprintf("[INFO] %s\n", msg))

DATA_DIR <- "/app/src/data"
OUT_DIR  <- "/app/src/out"
#DATA_DIR <- "src/data" #for the terminal local run
#OUT_DIR  <- "src/output"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

train_path <- file.path(DATA_DIR, "train.csv")
test_path  <- file.path(DATA_DIR, "test.csv")

if (!file.exists(train_path)) { loud(paste("ERROR: missing", train_path)); quit(status=1) }
if (!file.exists(test_path))  { loud(paste("ERROR: missing", test_path));  quit(status=1) }

loud(paste("Loading train:", train_path))
loud(paste("Loading test :", test_path))
train <- fread(train_path)
test  <- fread(test_path)
loud(paste("train dim:", paste(dim(train), collapse=" x ")))
loud(paste("test  dim:", paste(dim(test),  collapse=" x ")))

add_features <- function(dt) {
  dt <- copy(dt)
  loud("Feature: Title from Name")
  if ("Name" %in% names(dt)) {
    dt[, Title := str_match(Name, ",\\s*([^\\.]+)\\.")[,2]]
    map <- c(
      "Mlle"="Miss","Ms"="Miss","Mme"="Mrs",
      "Lady"="Noble","Countess"="Noble","Sir"="Noble",
      "Dona"="Noble","Don"="Noble","Jonkheer"="Noble",
      "Capt"="Officer","Col"="Officer","Major"="Officer",
      "Dr"="Officer","Rev"="Clergy"
    )
    dt[, Title := ifelse(Title %in% names(map), map[Title], Title)]
    dt[is.na(Title), Title := "Unknown"]
  } else dt[, Title := "Unknown"]

  loud("Feature: FamilySize = SibSp + Parch + 1")
  dt[, FamilySize := SibSp + Parch + 1L]

  loud("Feature: IsAlone = (FamilySize==1)")
  dt[, IsAlone := as.integer(FamilySize == 1L)]

  loud("Feature: CabinKnown = 1 if Cabin present")
  dt[, CabinKnown := as.integer(!is.na(Cabin))]

  loud("Feature: Deck = first letter of Cabin or 'U'")
  dt[, Deck := ifelse(is.na(Cabin), "U", substr(Cabin, 1, 1))]

  loud("Feature: Fare_log = log1p(Fare) with median fill")
  if ("Fare" %in% names(dt)) {
    fare_med <- suppressWarnings(median(dt$Fare, na.rm = TRUE))
    dt[is.na(Fare), Fare := fare_med]
    dt[, Fare_log := log1p(Fare)]
  } else dt[, Fare_log := 0]

  if ("Embarked" %in% names(dt)) {
    mode_emb <- names(sort(table(dt$Embarked), decreasing = TRUE))[1]
    dt[is.na(Embarked) | Embarked == "", Embarked := mode_emb]
  }
  if ("Age" %in% names(dt)) {
    age_med <- suppressWarnings(median(dt$Age, na.rm = TRUE))
    dt[is.na(Age), Age := age_med]
  }
  dt[]
}

train_fe <- add_features(train)
test_fe  <- add_features(test)

keep <- c("Survived","Pclass","Sex","Age","SibSp","Parch",
          "Fare_log","Embarked","Title","FamilySize","IsAlone","CabinKnown","Deck")
train_sel <- train_fe[, intersect(keep, names(train_fe)), with=FALSE]
test_sel  <- test_fe [, intersect(keep, names(test_fe )), with=FALSE]

loud("Preview engineered training rows:")
print(head(train_sel, 5))

to_factor <- intersect(c("Sex","Embarked","Title","Deck"), names(train_sel))
for (c in to_factor) train_sel[[c]] <- as.factor(train_sel[[c]])
to_factor_t <- intersect(c("Sex","Embarked","Title","Deck"), names(test_sel))
for (c in to_factor_t) test_sel[[c]] <- as.factor(test_sel[[c]])

# align factor levels
for (c in intersect(to_factor, to_factor_t)) {
  lv <- union(levels(train_sel[[c]]), levels(test_sel[[c]]))
  train_sel[[c]] <- factor(train_sel[[c]], levels=lv)
  test_sel[[c]]  <- factor(test_sel[[c]],  levels=lv)
}

if (!"Survived" %in% names(train_sel)) { loud("ERROR: train.csv missing 'Survived'"); quit(status=1) }

form <- as.formula(Survived ~ Pclass + Sex + Age + SibSp + Parch +
                   Fare_log + Embarked + Title + FamilySize + IsAlone + CabinKnown + Deck)

loud("Fitting glm (binomial)…")
fit <- glm(form, data=train_sel, family=binomial())
loud("Fit complete.")

train_prob <- predict(fit, newdata=train_sel, type="response")
train_pred <- as.integer(train_prob >= 0.5)
train_acc  <- mean(train_pred == train_sel$Survived)
loud(sprintf("Training accuracy: %.4f", train_acc))

has_test_y <- "Survived" %in% names(test_sel)
Xtest <- copy(test_sel); if (has_test_y) Xtest[, Survived := NULL]

loud("Predicting on test set…")
test_prob <- predict(fit, newdata=Xtest, type="response")
test_pred <- as.integer(test_prob >= 0.5)

if (has_test_y) {
  test_acc <- mean(test_pred == test_sel$Survived)
  loud(sprintf("Test accuracy: %.4f", test_acc))
} else {
  loud("No 'Survived' in test.csv — skipping test accuracy.")
}

pred <- data.table(PredSurvived = test_pred)
if ("PassengerId" %in% names(test)) pred <- cbind(PassengerId=test$PassengerId, pred)

out_path <- file.path(OUT_DIR, "predictions_r.csv")
fwrite(pred, out_path)
loud(paste("Saved predictions to:", out_path))
loud("✅ R pipeline completed successfully.")

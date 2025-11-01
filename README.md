# hw3_titanic_disaster

This repo sets up two pipelines in Python and R to 
1. Download and place the Titanic data locally,
2. Engineer features and train a logistic regression,
3. Print progress/metrics to the terminal,
4. generate predictions on survival to src/out/.

And this is the structure of the repo:
```
.
├─ Dockerfile                       # Python container
├─ out
├─ requirements.txt
├─ README.md
└─ src/
   ├─ app/
   │  └─ titanic_pipeline.py        # Python pipeline
   ├─ data/                         # (you put train.csv & test.csv here; not committed)
   ├─ out/                          # predictions written here (kept empty with .gitkeep)
   └─ r/
      ├─ Dockerfile                 # R container
      ├─ install_packages.R
      └─ app.R                      # R pipeline
```
Firstly git clone the repo and move you into the working directory:
```
https://github.com/Supershaaa/hw3_titanic_disaster.git
cd hw3_titanic_disaster
```

And then create the data & output folders in terminal, this is where you store the data:
```
mkdir -p src/data src/out
```
Then download the Titanic train and test dataset files from website: https://www.kaggle.com/competitions/titanic/models and place them here:
```
src/data/train.csv
src/data/test.csv
```
To run the python pipeline (Docker):
first, build the image in terminal
```
docker build -t titanic-app .
```
Then, run the container in terminal
```
docker run --rm \
  -v "$(pwd)/src/data:/app/src/data" \
  -v "$(pwd)/src/out:/app/src/out" \
  titanic-app
```
You will see logs about data loading, feature engineering, and model training.
Then, the training accuracy, and a file src/out/predictions.csv created.

To run the R pipeline (Docker):
first, build the image in terminal
```
docker build -t titanic-r src/r
```
Then, run the container in terminal
```
docker run --rm \
  -v "$(pwd)/src/data:/app/src/data" \
  -v "$(pwd)/src/out:/app/src/out" \
  titanic-r
```
You will see logs about data loading, feature engineering, and model training.
Then, the training accuracy, and a file src/out/predictions_r.csv created.








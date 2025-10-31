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

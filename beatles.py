import re
import os.path
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.naive_bayes import MultinomialNB
from sklearn import metrics

www = '/Users/gene/Documents/data/beatles-who-wrote-what.txt'
path = '/Users/gene/Documents/lit/Beatles/'

d = {}

with open(www) as f:
    for line in f:
        if not line.startswith('Album: '):
            if re.search(r'\w', line) and 'composer' not in line:
                song = line.split('\t')

                if len(song) > 1:
                    what = song[0].strip()
                    what = re.sub(r'\W', '_', what)

                    who = song[1].strip()

                    if ('Lennon' == who) or ('McCartney' == who):
                        filename = path + what + '.txt'

                        if os.path.isfile(filename):
                            with open(filename, encoding='latin1') as fh:
                                lyrics = fh.read()
                                d[what] = { 'author': who, 'lyrics': lyrics }

X = []
y = []

for key in sorted(d):
    X.append(d[key]['lyrics'])
    y.append(d[key]['author'])

X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=1)

vect = CountVectorizer() #stop_words='english' #ngram_range=(1, 2)

vect.fit(X_train)

X_train_dtm = vect.transform(X_train)

X_test_dtm = vect.transform(X_test)

nb = MultinomialNB(alpha=0.001)

nb.fit(X_train_dtm, y_train)

y_pred = nb.predict(X_test_dtm)

print(metrics.accuracy_score(y_test, y_pred)) # 0.625


# TF-IDF SCALE THE VOCABULARY
tfidf_transformer = TfidfTransformer()

X_train_tfidf = tfidf_transformer.fit_transform(X_train_dtm)

X_test_tfidf = tfidf_transformer.fit_transform(X_test_dtm)

nb = MultinomialNB(alpha=0.001)

nb.fit(X_train_tfidf, y_train)

y_pred = nb.predict(X_test_tfidf)

print(metrics.accuracy_score(y_test, y_pred)) # 0.625
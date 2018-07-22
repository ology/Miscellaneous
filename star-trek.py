# LOAD FILES INTO A DATAFRAME
import pandas as pd
import nltk.data

#nltk.download()

def file_to_df(path, name):
    fh = open(path + '/' + name + '.txt')
    data = fh.read()
    fh.close()
    tokenizer = nltk.data.load('/Users/gene/nltk_data/tokenizers/punkt/english.pickle')
    return pd.DataFrame(
        zip(
            tokenizer.tokenize(data),
            ([name] * len(tokenizer.tokenize(data)))
        ),
        columns=['text','person']
    )

path = '/Users/gene/Documents/lit/Kirk-and-Spock'

mccoy = file_to_df(path, 'mccoy')
spock = file_to_df(path, 'spock')
kirk  = file_to_df(path, 'kirk')

result = pd.concat([mccoy, spock, kirk])


# GET THE TRAIN/TEST DATA
X = result.text
y = result.person

from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=1)


# LEARN THE VOCABULARY
from sklearn.feature_extraction.text import CountVectorizer

vect = CountVectorizer() #stop_words='english' => 0.6598099205832574

X_train_dtm = vect.fit_transform(X_train)
X_test_dtm = vect.transform(X_test)


# TF-IDF SCALE THE VOCABULARY
#from sklearn.feature_extraction.text import TfidfTransformer
#tfidf_transformer = TfidfTransformer()
#X_train_tfidf = tfidf_transformer.fit_transform(X_train_dtm)
#X_test_tfidf = tfidf_transformer.fit_transform(X_test_dtm)


# TRAIN A CLASSIFIER
from sklearn.naive_bayes import MultinomialNB

#clf = MultinomialNB().fit(X_train_tfidf, y_train)
#y_pred = clf.predict(X_test_tfidf) # 0.628563989063924

clf = MultinomialNB().fit(X_train_dtm, y_train)
y_pred = clf.predict(X_test_dtm) # 0.6656685327431324


# EVALUATE THE MODEL ACCURACY
from sklearn import metrics

metrics.accuracy_score(y_test, y_pred)
#metrics.confusion_matrix(y_test, y_pred)


# PREDICT ARBITRARY PHRASES
docs = [ "Captian's log, Stardate...", 'That is highly illogical.', "He's dead Jim." ]

X_new_counts = vect.transform(docs)
predicted = clf.predict(X_new_counts)

for doc, who in zip(docs, predicted):
    print '%r => %s' % (doc, who)


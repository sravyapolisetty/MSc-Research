import numpy as np
import re
import itertools
from collections import Counter
import sys
from scipy import sparse
from keras.preprocessing.text import Tokenizer

PAD = "<PAD/>"
def load_labels(pos_file_name, neg_file_name):
    #TODO update comments
    """
    Loads polarity data from files, splits the data into words and generates labels.
    Returns split sentences and labels.
    """
    pos_labels_cnt = 0
    neg_labels_cnt = 0
    
    with open(pos_file_name) as f:
        for line in f:
            pos_labels_cnt = pos_labels_cnt + 1
            
    with open(neg_file_name) as f:
        for line in f:
            neg_labels_cnt = neg_labels_cnt + 1
            
    y = np.concatenate([[1] * pos_labels_cnt, [0] * neg_labels_cnt], 0)

    return y


def build_vocab_new(files):
    """
    Builds a vocabulary mapping from word to index based on the sentences.
    Returns vocabulary mapping and inverse vocabulary mapping.
    """
    vocabulary = {}
    word_id_cnt = 1
    max_words_in_sentence = 0
    for file in files:
        with open(file) as f:
            for line in f:
                words = line.strip().split(" ")
                
                #comput maximum number of words in a sentence
                if len(words) > max_words_in_sentence:
                    max_words_in_sentence = len(words)

                #build a mapping between word and numeric index
                for word in words:
                    if word not in vocabulary:
                        vocabulary[word] = word_id_cnt
                        word_id_cnt = word_id_cnt + 1

    #Add the padding word to the dictionary
    vocabulary[PAD] = 0


    #build an inverse vocabulary
    vocabulary_inv = {v: k for k, v in vocabulary.iteritems()}

    #print(vocabulary_inv)

    return [vocabulary, vocabulary_inv, max_words_in_sentence]

def build_input_data(files,labels, vocabulary, max_words_in_sentence):
    
    labels_cnt = len(labels)
    x = np.zeros((labels_cnt, max_words_in_sentence), dtype = np.int32)
    sentence_ind = 0
    for file in files:
        with open(file) as f:
            for line in f:
                words = line.strip().split(" ")
                word_ind = 0
                for word in words:
                    x[sentence_ind, word_ind] = vocabulary[word]
                    word_ind = word_ind + 1
                sentence_ind = sentence_ind +1

    return x

def load_data():
    """
    Loads and preprocessed data for the dataset.
    Returns input vectors, labels, vocabulary, and inverse vocabulary.
    """
    vocabulary, vocabulary_inv, max_words_in_sentence = build_vocab_new(["./data/rt-polarity.pos", "./data/rt-polarity.neg" ])
    y = load_labels("./data/rt-polarity.pos", "./data/rt-polarity.neg")
    x = build_input_data(["./data/rt-polarity.pos", "./data/rt-polarity.neg"],y, vocabulary, max_words_in_sentence)
    
    #vocabulary, vocabulary_inv, max_words_in_sentence = build_vocab_new(["./data/rt-polarity.pos.short", "./data/rt-polarity.neg.short" ])
    #y = load_labels("./data/rt-polarity.pos.short", "./data/rt-polarity.neg.short")
    #x = build_input_data(["./data/rt-polarity.pos.short", "./data/rt-polarity.neg.short"],y, vocabulary, max_words_in_sentence)
    
    #one_hot = (np.arange(x.max()+1) == x[...,None]).astype('int32')
    #one_hot = np.equal.outer(x,range(len(vocabulary_inv))).astype(bool)
 
    return [x, y, vocabulary, vocabulary_inv]


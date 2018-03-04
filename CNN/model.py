from keras.layers import Input, Dense, Embedding, merge, Convolution2D, MaxPooling2D, Dropout, Lambda
from sklearn.cross_validation import train_test_split
from keras.layers.core import Reshape, Flatten
from keras.callbacks import ModelCheckpoint
from data_helpers import load_data
from keras.optimizers import Adam
from keras.models import Model
from sklearn.model_selection import StratifiedKFold
from keras import backend as K
import numpy as np
import h5py
import tensorflow as tf
from sklearn import metrics
from keras import metrics as k_metrics
import functools
from keras.utils import multi_gpu_model
from sklearn.utils import class_weight


seed = 5
np.random.seed(seed)

print('Loading data')
x, y, vocabulary, vocabulary_inv = load_data()

shuffle_indices = np.random.permutation(np.arange(len(y)))
x = x[shuffle_indices]
y = y[shuffle_indices]

sequence_length = x.shape[1]

vocabulary_size = len(vocabulary_inv)
print("Vocabulary Size: {:d}".format(len(vocabulary_inv)))

nb_classes=vocabulary_size
filter_sizes = [2,3,4,5]
num_filters = 100
drop = 0.5

epochs = 25
batch_size = 64

hidden_dims = 100

#class_weight = {0 : 1.,
	#1: 1000.}

class_weight = class_weight.compute_class_weight('balanced', np.unique(y), y)
	
class_weight = {0: class_weight[0], 1: class_weight[1]}

print("Class Weight:",class_weight)

kfold = StratifiedKFold(n_splits=10, shuffle=True, random_state=seed)

cvscores = []
auc_scores = []

fold_counter = 0

for train, test in kfold.split(x, y):

	fold_counter = fold_counter + 1

	print("Current Fold : ", fold_counter)

	# to save test data of the current fold to file

	test_file_name = "test_data_" + 	str(fold_counter)
	true_labels_file_name = "true_labels_" + str(fold_counter)
	train_lables_file_name = "train_labels" + str(fold_counter)
	pred_file_name = "predictions_" + str(fold_counter)
	
	test_indices = test.flatten().tolist()
	#np.set_printoptions(threshold='nan')
	file_test = open(test_file_name, 'a')
	file_labels = open(true_labels_file_name, 'a')

	for i in test_indices:
		sent_text = np.vectorize(vocabulary_inv.get)(x[i]).tolist()
		new_sent_text = [j for j in sent_text if j != '<PAD/>']
		final_sent = ' '.join(new_sent_text) + "\n"
		file_test.write(final_sent)
		file_labels.write('%d\n' % y[i])
	
	file_test.close()
	file_labels.close()

	np.savetxt(train_lables_file_name,y[train],fmt="%1.2f")

	input_shape = (sequence_length,)
	output_shape = (input_shape[0], nb_classes)
	inputs = Input(shape=input_shape,dtype='int32')


	# One-Hot Encoding Layer

	ohe=Lambda(K.one_hot,arguments={'num_classes': nb_classes},output_shape=output_shape)(inputs)
	
	reshape = Reshape((sequence_length,nb_classes,1))(ohe)

	conv_0 = Convolution2D(num_filters, filter_sizes[0], nb_classes, border_mode='valid', init='normal', activation='relu', dim_ordering='tf')(reshape)
	conv_1 = Convolution2D(num_filters, filter_sizes[1], nb_classes, border_mode='valid', init='normal', activation='relu', dim_ordering='tf')(reshape)
	conv_2 = Convolution2D(num_filters, filter_sizes[2], nb_classes, border_mode='valid', init='normal', activation='relu', dim_ordering='tf')(reshape)
	conv_3 = Convolution2D(num_filters, filter_sizes[3], nb_classes, border_mode='valid', init='normal', activation='relu', dim_ordering='tf')(reshape)
	
	maxpool_0 = MaxPooling2D(pool_size=(sequence_length - filter_sizes[0] + 1, 1), strides=(1,1), border_mode='valid', dim_ordering='tf')(conv_0)
	maxpool_1 = MaxPooling2D(pool_size=(sequence_length - filter_sizes[1] + 1, 1), strides=(1,1), border_mode='valid', dim_ordering='tf')(conv_1)
	maxpool_2 = MaxPooling2D(pool_size=(sequence_length - filter_sizes[2] + 1, 1), strides=(1,1), border_mode='valid', dim_ordering='tf')(conv_2)
	maxpool_3 = MaxPooling2D(pool_size=(sequence_length - filter_sizes[3] + 1, 1), strides=(1,1), border_mode='valid', dim_ordering='tf')(conv_3)
	
	merged_tensor = merge([maxpool_0, maxpool_1, maxpool_2, maxpool_3], mode='concat', concat_axis=1)

	flatten = Flatten()(merged_tensor)
	
	dropout = Dropout(drop)(flatten)

	dense = Dense(hidden_dims, activation="relu")(dropout)

	output = Dense(1, activation="sigmoid")(dense)

	
	# this creates a model that includes all the above layers.
	
	model = Model(input=inputs, output=output)

	checkpoint = ModelCheckpoint('weights.best.hdf5', monitor='val_acc', verbose=1, save_best_only=True, mode='auto')

	callbacks_list = [checkpoint]
	
	adam = Adam(lr=1e-4, beta_1=0.9, beta_2=0.999, epsilon=1e-08)

	model.compile(optimizer=adam, loss='binary_crossentropy', metrics=['accuracy'])

	model.fit(x[train], y[train], batch_size=batch_size, epochs=epochs, verbose=1, validation_split=0.1, class_weight = class_weight,callbacks=callbacks_list)  # starts training

	# Load weights which gave best val accuracy and compile the model. Evaluate on test set and calculate metrics

	print('Loading Best Weights..')

	model.load_weights("weights.best.hdf5")

	model.compile(optimizer=adam, loss='binary_crossentropy', metrics=['accuracy'])

	print('Evaluating on Best Weights..')

	scores = model.evaluate(x[test], y[test], verbose=0)

	yp = model.predict(x[test], batch_size=50, verbose=1)

	np.savetxt(pred_file_name,yp,fmt="%1.2f")
	
	auc = metrics.roc_auc_score(y[test],yp)

	print("AUC",auc)

	print("%s: %.2f%%" % ('Binary Classification Accuracy', scores[1]*100))

	cvscores.append(scores[1] * 100)

	auc_scores.append(auc)


print("%.2f%% (+/- %.2f%%)" % (np.mean(cvscores), np.std(cvscores)))

print("%.2f (+/- %.2f)" % (np.mean(auc_scores), np.std(auc_scores)))



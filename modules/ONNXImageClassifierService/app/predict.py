import sys
import os
import io
import json

import onnxruntime as rt
import numpy as np
from PIL import Image # Imports for image procesing
from urllib.request import urlopen

filename = 'model.onnx'

network_input_shape = (0,0,0,0)
network_input_name = ""
input_image_size = (0,0)

sess = None

def initialize():
    print('Loading model...',end=''),
    global sess, network_input_name, network_input_shape, input_image_size
    sess = rt.InferenceSession(filename)
    print('Success!')

    network_input = sess.get_inputs()[0]
    network_input_name = network_input.name
    network_input_shape = network_input.shape
    input_image_size = (network_input.shape[2], network_input.shape[3])

def crop_center(img,cropx,cropy):
    y,x,z = img.shape
    startx = x//2-(cropx//2)
    starty = y//2-(cropy//2)
    return img[starty:starty+cropy,startx:startx+cropx]

def resize_and_crop(image, shape):
    w, h = image.size

    # scaling
    if w > h:
        new_size = (int((float(shape[1]) / h) * w), shape[1], 3)
    else:
        new_size = (shape[0], int((float(shape[0]) / w) * h), 3)

    # resize
    if not (new_size[0] == w and new_size[0] == h):
        augmented_image = np.asarray(image.resize((new_size[0], new_size[1])))
    else:
        augmented_image = np.asarray(image)

    # crop center
    augmented_image = crop_center(augmented_image, shape[0], shape[1])

    return augmented_image

def predict_image(image):
    print('Predicting image')

    image = image.convert("RGB") if image.mode != "RGB" else image
    try:
        augmented_image = resize_and_crop(image, input_image_size)
    except:
        return None

    inputs = np.array(augmented_image, dtype=np.float32)[:,:,(2,1,0)] # RGB -> BGR
    inputs = np.ascontiguousarray(np.rollaxis(inputs, 2))
    inputs = np.expand_dims(inputs, axis=0) # add a fourth dimension (# frames)

    # run the prediction
    onnx_output = sess.run(None, {network_input_name: inputs})

    result = []
    for tag,prob in onnx_output[1][0].items():
        truncated_probablity = np.float64(round(prob,8))
        if (truncated_probablity > 1e-8):
            result.append({'Tag': tag, 'Probability': truncated_probablity })
    print('Results:', str(result))
    return result

def predict_url(imageUrl):
    print('Predicting from url: ',imageUrl)
    with urlopen(imageUrl) as testImage:
        image = Image.open(testImage)
        return predict_image(image)

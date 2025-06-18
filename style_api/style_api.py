from flask import Flask, request, jsonify
from PIL import Image, ImageEnhance
import io
import numpy as np
import os

app = Flask(__name__)

def apply_warm_tone(image):
    img_array = np.array(image).astype(float)
    img_array[:, :, 0] *= 1.2
    img_array[:, :, 1] *= 1.1  
    img_array = np.clip(img_array, 0, 255).astype(np.uint8)
    return Image.fromarray(img_array)

def apply_cool_tone(image):
    img_array = np.array(image).astype(float)
    img_array[:, :, 2] *= 1.2
    img_array[:, :, 1] *= 1.5 
    img_array = np.clip(img_array, 0, 255).astype(np.uint8)
    return Image.fromarray(img_array)

def apply_vintage(image):
    converter = ImageEnhance.Color(image)
    desaturated = converter.enhance(0.8)
    img_array = np.array(desaturated).astype(float)
    img_array[:, :, 0] *= 1.5
    img_array[:, :, 1] *= 1.2
    img_array = np.clip(img_array, 0, 255).astype(np.uint8)
    return Image.fromarray(img_array)


def apply_sepia(image):
    img_array = np.array(image).astype(float)
    tr = 0.393 * img_array[:, :, 0] + 0.769 * img_array[:, :, 1] + 0.189 * img_array[:, :, 2]
    tg = 0.349 * img_array[:, :, 0] + 0.686 * img_array[:, :, 1] + 0.168 * img_array[:, :, 2]
    tb = 0.272 * img_array[:, :, 0] + 0.534 * img_array[:, :, 1] + 0.131 * img_array[:, :, 2]
    img_array[:, :, 0] = np.clip(tr, 0, 255)
    img_array[:, :, 1] = np.clip(tg, 0, 255)
    img_array[:, :, 2] = np.clip(tb, 0, 255)
    return Image.fromarray(img_array.astype(np.uint8))

def apply_matte(image):
    img_array = np.array(image).astype(float)
    img_array = img_array * 0.9 + 20
    img_array = np.clip(img_array, 0, 255)
    return Image.fromarray(img_array.astype(np.uint8))

def apply_teal_orange(image):
    img_array = np.array(image).astype(float)
    img_array[:, :, 0] *= 1.1
    img_array[:, :, 1] *= 1.1  
    img_array[:, :, 2] *= 0.9 
    img_array = np.clip(img_array, 0, 255)
    return Image.fromarray(img_array.astype(np.uint8))

def apply_noir(image):
    gray = image.convert('L')
    gray = ImageEnhance.Contrast(gray).enhance(1.5)
    return gray.convert('RGB')

def apply_pastel(image):
    img_array = np.array(image).astype(float)
    img_array = img_array * 0.8 + 50
    img_array = np.clip(img_array, 0, 255)
    return Image.fromarray(img_array.astype(np.uint8))

def apply_moody(image):
    img_array = np.array(image).astype(float)
    img_array[:, :, 0] *= 0.7 
    img_array[:, :, 1] *= 1.2  
    img_array[:, :, 2] *= 0.9 
    img_array = np.clip(img_array, 0, 255)
    return Image.fromarray(img_array.astype(np.uint8))

def apply_infrared(image):
    img_array = np.array(image)
    img_array[:, :, [0, 2]] = img_array[:, :, [2, 0]]
    return Image.fromarray(img_array)


def adjust_intensity(image, factor):
    enhancer = ImageEnhance.Brightness(image)
    return enhancer.enhance(factor)

def adjust_contrast(image, factor):
    enhancer = ImageEnhance.Contrast(image)
    return enhancer.enhance(factor)

@app.route('/apply_style', methods=['POST'])
def apply_style_endpoint():
    print("Received /apply_style request")
    print("Files:", request.files)
    print("Form:", request.form)

    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    image_file = request.files['image']
    try:
        image = Image.open(io.BytesIO(image_file.read())).convert("RGB")
        print("Image opened successfully:", image.format, image.size)
    except Exception as e:
        print(f"Error opening image: {str(e)}")
        return jsonify({'error': f'Error opening image: {str(e)}'}), 400

    style = request.form.get('style', 'original')
    print(f"Selected style: {style}")
    try:
        intensity = float(request.form.get('intensity', 1.0))
        contrast = float(request.form.get('contrast', 1.0))
        print(f"Intensity: {intensity}, Contrast: {contrast}")
    except ValueError:
        return jsonify({'error': 'Invalid intensity or contrast value'}), 400

    processed_image = image

    if style == 'warm':
        processed_image = apply_warm_tone(processed_image)
        print("Warm tone applied")
    elif style == 'cool':
        processed_image = apply_cool_tone(processed_image)
        print("Cool tone applied")
    elif style == 'vintage':
        processed_image = apply_vintage(processed_image)
        print("Vintage tone applied")

    elif style == 'sepia':
        processed_image = apply_sepia(processed_image)
        print("Sepia tone applied")
    elif style == 'matte':
        processed_image = apply_matte(processed_image)
        print("Matte tone applied")
    elif style == 'teal_orange':
        processed_image = apply_teal_orange(processed_image)
        print("Teal & Orange tone applied")
    elif style == 'noir':
        processed_image = apply_noir(processed_image)
        print("Noir tone applied")
    elif style == 'pastel':
        processed_image = apply_pastel(processed_image)
        print("Pastel tone applied")
    elif style == 'moody':
        processed_image = apply_moody(processed_image)
        print("Moody tone applied")
    elif style == 'infrared':
        processed_image = apply_infrared(processed_image)
        print("Infrared tone applied")
    else:
        print("No style applied (original)")

    processed_image = adjust_intensity(processed_image, intensity)
    print("Intensity adjusted")
    processed_image = adjust_contrast(processed_image, contrast)
    print("Contrast adjusted")

    img_byte_arr = io.BytesIO()
    try:
        processed_image.save(img_byte_arr, format='PNG')
        img_byte_arr_value = img_byte_arr.getvalue()
        print(f"Processed image saved to bytes: {len(img_byte_arr_value)} bytes")
        return img_byte_arr_value, 200, {'Content-Type': 'image/png'}
    except Exception as e:
        print(f"Error saving processed image: {str(e)}")
        return jsonify({'error': f'Error saving processed image: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
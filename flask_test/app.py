from flask import Flask, render_template
app = Flask(__name__)

import xml.etree.ElementTree as ET

def get_lines(xml_file):
    tree = ET.parse(xml_file)
    root = tree.getroot()
    all_text = []
    count = len(root.findall(".//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}RegionRefIndexed"))
    all_coords = []

    for i in range (0,count):
        region_ref = root.findall(".//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}RegionRefIndexed")[i].attrib['regionRef']
        #print("In region", i,'    RegionRef:', region_ref)
        all_text.append('In Region ' + str(i + 1))
        text_regions = root.findall(".//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}TextRegion")
        for region in text_regions:
            if i == 0:
                region_coords = region.findall('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}Coords')[0].attrib['points']
                all_coords.append(region_coords)
            if region.attrib['id'] == region_ref:
                text_lines = region.findall('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}TextLine')
                for line in text_lines:
                    if float(line.findall('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}TextEquiv')[-1].attrib['conf']) >= 0.5:
                        all_text.append(line.findall('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}Unicode')[-1].text)
                    else:
                        all_text.append(line.findall('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}Unicode')[-1].text + ' *')
        #print('\n')
        all_text.append('\n')
    return all_coords, all_text

xml_file = "/Users/waldo/Library/CloudStorage/OneDrive-Personal/Master Thesis/Temporary_data/page_all/53_fac_03008_verksamhetsberattelse_1964_sid-03.xml"
all_coords, all_text = get_lines(xml_file)
txt_string = ''

for text in all_text:
    txt_string += text + '\n'

txt_string = txt_string + 'Predicted lines end with * suggests that the \nmodel is not confident about the prediction \nor this line is not present in the document.'

from PIL import Image, ImageDraw, ImageFont

def draw_rectangular_area(idx, img, coordinates, opacity, color):
    text = "Region " + str(idx+1)
    #color = color[idx%3]
    color = color[0]
    font = ImageFont.truetype(font='Keyboard.ttf',size=60)
    overlay = Image.new('RGBA', img.size, color+(0,))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle(coordinates, fill=color+(int(opacity * 255),))
    #draw.text(((coordinates[1][0]+coordinates[0][0])*0.6,coordinates[1][1]-150), text, fill=(0,0,0), font=font)
    draw.text((coordinates[0][0],coordinates[0][1]-80), text, fill=(0,0,0), font=font)
    
    
    img = Image.alpha_composite(img, overlay)

    return img

image_path = "/Users/waldo/Library/CloudStorage/OneDrive-Personal/Master Thesis/Temporary_data/53_fac_03008_verksamhetsberattelse_1964_sid-03.jpg"
coordinates = [(800, 2716), (3558,4006)]
opacity = 0.1
color = [(255, 0, 0),(0, 255, 0),(154, 100, 250)]

img = Image.open(image_path)
img = img.convert("RGBA")
for idx, coord in  enumerate(all_coords):
    img = draw_rectangular_area(idx, img, [(int(coord.split(' ')[0].split(',')[0]),int(coord.split(' ')[0].split(',')[1])),(int(coord.split(' ')[2].split(',')[0]),int(coord.split(' ')[2].split(',')[1]))], opacity, color)
#img.show()
img.save('/Users/waldo/Documents/master thesis/flask_test/static/output.png')




@app.route('/')
def index():

    image_path = "/static/output.png"
    text_content = txt_string
    
    return render_template('index.html', image_path=image_path, text_content=text_content)

if __name__ == '__main__':
    app.run(port=5001)
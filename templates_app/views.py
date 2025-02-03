from rest_framework import generics
from .models import Template, TemplateEdit
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from PIL import Image, ImageDraw, ImageFont
import requests
from io import BytesIO
import json
from django.views.decorators.csrf import csrf_exempt
from .models import Template
from .serializers import TemplateSerializer, TemplateEditSerializer

class TemplateListView(generics.ListAPIView):
    queryset = Template.objects.all()
    serializer_class = TemplateSerializer

class TemplateDetailView(generics.RetrieveAPIView):
    queryset = Template.objects.all()
    serializer_class = TemplateSerializer

class TemplateEditCreateView(generics.CreateAPIView):
    queryset = TemplateEdit.objects.all()
    serializer_class = TemplateEditSerializer

@csrf_exempt
def upload_image(request):
    if request.method == "POST":
        image = request.FILES.get("image")
        if image:
            # Save the image to the media folder
            with open(f"media/{image.name}", "wb") as f:
                f.write(image.read())
            image_url = f"http://{request.get_host()}/media/{image.name}"
            return HttpResponse(json.dumps({"url": image_url}), content_type="application/json")
        else:
            return HttpResponse("No image found in the request", status=400)
    return HttpResponse("Invalid request method", status=405)


@csrf_exempt
def generate_template_preview(request, template_id):
    if request.method == 'POST':
        try:
            # Parse the request body
            data = json.loads(request.body)
            edited_json = data.get('edited_json', {})
            elements = edited_json.get('editable_elements', [])
        except json.JSONDecodeError:
            return HttpResponse("Invalid JSON data", status=400)
    else:
        return HttpResponse("Method not allowed", status=405)

    template = get_object_or_404(Template, id=template_id)
    
    # Load background image
    image_url = f'http://192.168.1.6:8000/media/{template.image}'
    response = requests.get(image_url)
    if response.status_code != 200:
        return HttpResponse("Failed to load template image", status=500)
    
    bg_image = Image.open(BytesIO(response.content)).convert("RGBA")
    bg_image = bg_image.resize((template.canvas_width, template.canvas_height), Image.Resampling.LANCZOS)
    
    element_layer = Image.new('RGBA', (template.canvas_width, template.canvas_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(element_layer)

    # Sort elements by z-index
    elements.sort(key=lambda x: x.get('z_index', 0))
    
    for element in elements:
        box = element['box']
        element_type = element['type']
        
        # Get box coordinates
        box_x = int(box['x'])
        box_y = int(box['y'])
        box_width = int(box['width'])
        box_height = int(box['height'])
        
        if element_type == "text":
            text = element['content'].get('text', '')
            font_size = int(element['style'].get('font_size', 48))
            try:
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                font = ImageFont.load_default()
            
            # Calculate text dimensions
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # Calculate text position based on box alignment
            if box['alignment'] == "center":
                text_x = box_x + (box_width - text_width) // 2
            elif box['alignment'] == "right":
                text_x = box_x + box_width - text_width
            else:  # left alignment
                text_x = box_x
            
            # Vertically center the text in the box
            text_y = box_y + (box_height - text_height) // 2
            
            # Draw text
            color = element['style'].get('color', '#000000')
            # Remove the '#' and convert to RGB
            color = color.lstrip('#')
            rgb_color = tuple(int(color[i:i+2], 16) for i in (0, 2, 4))
            draw.text((text_x, text_y), text, fill=rgb_color, font=font)
        
        elif element_type == "image":
            image_url = element['content'].get('url')
            if image_url:
                try:
                    response = requests.get(image_url)
                    if response.status_code == 200:
                        element_image = Image.open(BytesIO(response.content))
                        element_image = element_image.resize((box_width, box_height), Image.Resampling.LANCZOS)
                        
                        # Convert element_image to RGBA if it isn't already
                        if element_image.mode != 'RGBA':
                            element_image = element_image.convert('RGBA')
                            
                        element_layer.paste(element_image, (box_x, box_y), element_image)
                except Exception as e:
                    print(f"Error processing image element: {e}")

    # Composite the element layer onto the background
    final_image = Image.alpha_composite(bg_image.convert('RGBA'), element_layer)
    
    # Save image to buffer
    img_io = BytesIO()
    final_image.save(img_io, format='PNG')
    img_io.seek(0)
    
    return HttpResponse(img_io.getvalue(), content_type="image/png")
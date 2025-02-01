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
def generate_template_preview(request, template_id):
    template = get_object_or_404(Template, id=template_id)

    # Ensure JSON is correctly parsed
    if isinstance(template.editable_json, dict):
        editable_elements = template.editable_json
    else:
        editable_elements = json.loads(template.editable_json)

    print("Editable Elements:", editable_elements)

    # Load background image
    image_url = f'http://192.168.1.6:8000/media/{template.image}'
    response = requests.get(image_url)
    if response.status_code != 200:
        return HttpResponse("Failed to load template image", status=500)
    
    # Open image and maintain original dimensions
    bg_image = Image.open(BytesIO(response.content)).convert("RGB")
    
    # Create a new image with the template's stored dimensions if they exist
    if template.image_width and template.image_height:
        bg_image = bg_image.resize((template.image_width, template.image_height), Image.Resampling.LANCZOS)
    
    draw = ImageDraw.Draw(bg_image)

    # Try loading a font with size relative to image height
    font_size = 45  # 5% of image height
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", font_size)
        except:
            font = ImageFont.load_default()

    # Draw editable elements
    for element in editable_elements.get("elements", []):
        try:
            # Use absolute positioning based on stored dimensions
            x = int(template.image_width * element["x"])
            y = int(template.image_height * element["y"])
            text = element.get("text", "")
            hex_color = element.get("color", "#000000")

            # Convert hex color to RGB
            rgb_color = tuple(int(hex_color[i:i+2], 16) for i in (1, 3, 5))

            # Get text dimensions for centering
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # Center text at position
            text_x = x - (text_width // 2)
            text_y = y - (text_height // 2)

            print(f"Placing text at: ({text_x}, {text_y}) with content: {text}")

            # Draw text
            draw.text((text_x, text_y), text, fill=rgb_color, font=font)
        except Exception as e:
            print("Error drawing element:", e)

    # Convert image to response
    img_io = BytesIO()
    bg_image.save(img_io, "PNG")
    img_io.seek(0)
    return HttpResponse(img_io.getvalue(), content_type="image/png")

# @csrf_exempt
# def generate_template_preview(request, template_id):
#     template = get_object_or_404(Template, id=template_id)

#     # Ensure JSON is correctly parsed
#     if isinstance(template.editable_json, dict):
#         editable_elements = template.editable_json
#     else:
#         editable_elements = json.loads(template.editable_json)

#     print("Editable Elements:", editable_elements)  # Debugging

#     # Load background image
#     image_url = f'http://192.168.1.6:8000/media/{template.image}'
#     response = requests.get(image_url)
#     if response.status_code != 200:
#         return HttpResponse("Failed to load template image", status=500)
    
#     bg_image = Image.open(BytesIO(response.content)).convert("RGB")  # Ensure it's RGB mode
#     draw = ImageDraw.Draw(bg_image)

#     # Try loading a font, fallback to default
#     try:
#         font = ImageFont.truetype("arial.ttf", 1000)
#     except:
#         try:
#             font = ImageFont.truetype("DejaVuSans-Bold.ttf", 1000)
#         except:
#             font = ImageFont.load_default(50)

#     # Draw editable elements
#     for element in editable_elements.get("elements", []):
#         try:
#             x = int(bg_image.width * element["x"])
#             y = int(bg_image.height * element["y"])
#             text = element.get("text", "")
#             hex_color = element.get("color", "#000000")

#             # Convert hex color to RGB
#             rgb_color = tuple(int(hex_color[i:i+2], 16) for i in (1, 3, 5))

#             print(f"Placing text at: ({x}, {y}) with content: {text}, color: {rgb_color}")  # Debugging

#             draw.text((x, y), text, fill=rgb_color, font=font)
#         except Exception as e:
#             print("Error drawing element:", e)

#     # Convert image to response
#     img_io = BytesIO()
#     bg_image.save(img_io, "PNG")
#     img_io.seek(0)
#     return HttpResponse(img_io.getvalue(), content_type="image/png")
from rest_framework import generics
from .models import Template, TemplateEdit, TemplateElement
from django.http import HttpResponse
from rest_framework import status
from django.shortcuts import get_object_or_404
from PIL import Image, ImageDraw, ImageFont
import requests
from io import BytesIO
import json
from django.views.decorators.csrf import csrf_exempt
from .models import Template
from .serializers import TemplateEditSerializer, TemplateSerializer, TemplateElementSerializer

class TemplateListView(generics.ListAPIView):
    queryset = Template.objects.all()
    serializer_class = TemplateSerializer

class TemplateDetailView(generics.RetrieveAPIView):
    queryset = Template.objects.all()
    serializer_class = TemplateSerializer

class TemplateEditCreateView(generics.CreateAPIView):
    queryset = TemplateEdit.objects.all()
    serializer_class = TemplateEditSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return HttpResponse(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        serializer.save()

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
    if request.method != 'POST':
        return HttpResponse("Method not allowed", status=405)

    try:
        data = json.loads(request.body)
        edited_json = data.get('edited_json', {})
        elements = edited_json.get('editable_elements', [])
        
        # Get viewport dimensions from request
        viewport = edited_json.get('viewport', {})
        viewport_width = viewport.get('width', 1080)
        viewport_height = viewport.get('height', 1920)
    except json.JSONDecodeError:
        return HttpResponse("Invalid JSON data", status=400)

    template = get_object_or_404(Template, id=template_id)
    
    # Load background image
    response = requests.get(f'http://192.168.1.6:8000/media/{template.image}')
    if response.status_code != 200:
        return HttpResponse("Failed to load template image", status=500)

    # Create background image maintaining aspect ratio
    bg_image = Image.open(BytesIO(response.content)).convert("RGBA")
    original_width, original_height = bg_image.size
    
    # Set output dimensions (maintain aspect ratio of original image)
    if original_width > original_height:
        output_width = 1920  # Full HD width
        output_height = int((original_height / original_width) * output_width)
    else:
        output_height = 1920  # Full HD height
        output_width = int((original_width / original_height) * output_height)

    # Resize background
    bg_image = bg_image.resize((output_width, output_height), Image.Resampling.LANCZOS)
    
    # Create transparent layer for elements
    element_layer = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(element_layer)

    # Sort elements by z-index
    elements.sort(key=lambda x: x.get('z_index', 0))
    
    for element in elements:
        box = element['box']
        element_type = element['type']
        
        # Convert percentage positions to pixels
        box_x = int((float(box['x_percent']) / 100) * output_width)
        box_y = int((float(box['y_percent']) / 100) * output_height)
        box_width = int((float(box['width_percent']) / 100) * output_width)
        box_height = int((float(box['height_percent']) / 100) * output_height)
        
        if element_type == "text":
            text = element['content'].get('text', '')
            
            # Calculate font size based on viewport width percentage
            # Font size comes in as vw units (viewport width percentage)
            font_size_vw = float(element['style'].get('font_size', 4.0))
            
            # Convert vw to pixels based on output width
            # The key change is here - we calculate font size relative to element width
            font_size_px = int((font_size_vw / 100) * box_width)
            
            try:
                # Try different system fonts
                try:
                    font = ImageFont.truetype("arial.ttf", font_size_px)
                except:
                    try:
                        font = ImageFont.truetype("Arial.ttf", font_size_px)
                    except:
                        try:
                            font = ImageFont.truetype("DejaVuSans.ttf", font_size_px)
                        except:
                            font = ImageFont.load_default()
            except Exception as e:
                print(f"Font loading error: {e}")
                font = ImageFont.load_default()
            
            # Calculate text dimensions for positioning
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
            color = color.lstrip('#')
            rgb_color = tuple(int(color[i:i+2], 16) for i in (0, 2, 4))
            
            # Draw text with subtle stroke for better visibility
            stroke_width = max(1, int(font_size_px * 0.02))  # Reduced stroke width
            draw.text(
                (text_x, text_y),
                text,
                fill=rgb_color + (255,),  # Add alpha channel
                font=font,
                stroke_width=stroke_width,
                stroke_fill=(255, 255, 255, 80)  # Reduced stroke opacity
            )
        
        elif element_type == "image":
            image_url = element['content'].get('url')
            if image_url:
                try:
                    response = requests.get(image_url)
                    if response.status_code == 200:
                        element_image = Image.open(BytesIO(response.content))
                        element_image = element_image.resize(
                            (box_width, box_height), 
                            Image.Resampling.LANCZOS
                        )
                        
                        if element_image.mode != 'RGBA':
                            element_image = element_image.convert('RGBA')
                            
                        element_layer.paste(element_image, (box_x, box_y), element_image)
                except Exception as e:
                    print(f"Error processing image element: {e}")

    # Composite the element layer onto the background
    final_image = Image.alpha_composite(bg_image.convert('RGBA'), element_layer)
    
    # Save with high quality
    img_io = BytesIO()
    final_image.save(
        img_io, 
        format='PNG',
        optimize=False,  # Disable optimization for better quality
        quality=100,    # Maximum quality
    )
    img_io.seek(0)
    
    response = HttpResponse(img_io.getvalue(), content_type="image/png")
    response['Cache-Control'] = 'no-cache'
    return response
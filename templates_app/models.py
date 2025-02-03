from django.db import models
from PIL import Image

class Template(models.Model):
    CATEGORY_CHOICES = [
        ("election", "Election"),
        ("announcement", "Announcement"),
        ("event", "Event"),
    ]

    name = models.CharField(max_length=255)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    image = models.ImageField(upload_to="templates/")
    preview_image = models.ImageField(upload_to="previews/", blank=True, null=True)
    is_premium = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    editable_json = models.JSONField(default=dict)
    original_width = models.IntegerField(default=1080)
    original_height = models.IntegerField(default=1920)
    aspect_ratio = models.FloatField(default=1.0)

    def save(self, *args, **kwargs):
        if self.image:
            with Image.open(self.image) as img:
                self.original_width = img.width
                self.original_height = img.height
                self.aspect_ratio = float(img.width) / float(img.height)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class TemplateEdit(models.Model):
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="edits")
    user_id = models.CharField(max_length=100)
    edited_json = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Edit by {self.user_id} on {self.template.name}"

class Box(models.Model):
    """Model to represent a bounding box for template elements using percentage-based positioning"""
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="boxes")
    # Store positions and dimensions as percentages (0-100)
    x_percent = models.FloatField()  # Left position as percentage of canvas width
    y_percent = models.FloatField()  # Top position as percentage of canvas height
    width_percent = models.FloatField()  # Width as percentage of canvas width
    height_percent = models.FloatField()  # Height as percentage of canvas height
    alignment = models.CharField(
        max_length=20,
        choices=[
            ("left", "Left"),
            ("center", "Center"),
            ("right", "Right"),
        ],
        default="left"
    )

    def clean(self):
        # Validate percentage values are between 0 and 100
        self.x_percent = max(0, min(100, self.x_percent))
        self.y_percent = max(0, min(100, self.y_percent))
        self.width_percent = max(0, min(100, self.width_percent))
        self.height_percent = max(0, min(100, self.height_percent))

        # Ensure element stays within bounds
        if self.x_percent + self.width_percent > 100:
            self.width_percent = 100 - self.x_percent
        if self.y_percent + self.height_percent > 100:
            self.height_percent = 100 - self.y_percent

    def get_pixel_values(self, canvas_width, canvas_height):
        """Convert percentage values to pixels for a given canvas size"""
        return {
            'x': int((self.x_percent / 100) * canvas_width),
            'y': int((self.y_percent / 100) * canvas_height),
            'width': int((self.width_percent / 100) * canvas_width),
            'height': int((self.height_percent / 100) * canvas_height)
        }

class TemplateElement(models.Model):
    """Model to represent individual elements within a template"""
    ELEMENT_TYPES = [
        ("text", "Text"),
        ("image", "Image"),
        ("shape", "Shape")
    ]
    
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="elements")
    box = models.ForeignKey(Box, on_delete=models.CASCADE, related_name="elements")
    element_type = models.CharField(max_length=20, choices=ELEMENT_TYPES)
    content = models.JSONField()  # Stores element-specific data
    style = models.JSONField()  # Stores styling information with relative units
    z_index = models.IntegerField(default=0)

    def get_scaled_style(self, canvas_width, canvas_height):
        """Convert relative style values to absolute values for rendering"""
        scaled_style = self.style.copy()
        if 'font_size' in scaled_style:
            # Convert font size from viewport units to pixels
            vw = canvas_width / 100
            scaled_style['font_size'] = int(float(scaled_style['font_size']) * vw)
        return scaled_style
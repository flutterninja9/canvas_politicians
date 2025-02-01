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
    canvas_width = models.IntegerField(default=1080)
    canvas_height = models.IntegerField(default=1920)

    def save(self, *args, **kwargs):
        if self.image and (not self.canvas_width or not self.canvas_height):
            with Image.open(self.image) as img:
                self.canvas_width = img.width
                self.canvas_height = img.height
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class Box(models.Model):
    """Model to represent a bounding box for template elements"""
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="boxes")
    x = models.IntegerField()  # Left position in pixels
    y = models.IntegerField()  # Top position in pixels
    width = models.IntegerField()  # Width in pixels
    height = models.IntegerField()  # Height in pixels
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
        # Validate that box stays within canvas bounds
        if self.x < 0:
            self.x = 0
        if self.y < 0:
            self.y = 0
        if self.x + self.width > self.template.canvas_width:
            self.x = self.template.canvas_width - self.width
        if self.y + self.height > self.template.canvas_height:
            self.y = self.template.canvas_height - self.height

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
    content = models.JSONField()  # Stores element-specific data (text content, image URL, etc.)
    style = models.JSONField()  # Stores styling information (color, font size, etc.)
    z_index = models.IntegerField(default=0)  # For layering elements

class TemplateEdit(models.Model):
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="edits")
    user_id = models.CharField(max_length=100)
    edited_json = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Edit by {self.user_id} on {self.template.name}"
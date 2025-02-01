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
    canvas_width = models.IntegerField(default=1080)  # Default canvas width
    canvas_height = models.IntegerField(default=1920)  # Default canvas height

    def save(self, *args, **kwargs):
        # Update canvas dimensions if image exists
        if self.image and (not self.canvas_width or not self.canvas_height):
            with Image.open(self.image) as img:
                self.canvas_width = img.width
                self.canvas_height = img.height
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class TemplateEdit(models.Model):
    template = models.ForeignKey(Template, on_delete=models.CASCADE, related_name="edits")
    user_id = models.CharField(max_length=100)  # Replace with actual user handling later
    edited_json = models.JSONField()  # Store user changes (text, images, colors, positions)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Edit by {self.user_id} on {self.template.name}"
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
    # Add fields for image dimensions
    image_width = models.IntegerField(default=0)
    image_height = models.IntegerField(default=0)

    def save(self, *args, **kwargs):
        # Update image dimensions on save if image exists
        if self.image and not self.image_width:
            with Image.open(self.image) as img:
                self.image_width = img.width
                self.image_height = img.height
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

from rest_framework import serializers
from .models import Template, TemplateEdit

class TemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Template
        fields = "__all__"

class TemplateEditSerializer(serializers.ModelSerializer):
    class Meta:
        model = TemplateEdit
        fields = "__all__"

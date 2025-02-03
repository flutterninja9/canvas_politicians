from rest_framework import serializers
from .models import Template, TemplateEdit, TemplateElement

class TemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Template
        fields = "__all__"

class TemplateEditSerializer(serializers.ModelSerializer):
    class Meta:
        model = TemplateEdit
        fields = "__all__"
        
    def validate_edited_json(self, value):
        """
        Validate the structure of edited_json while being flexible with the new format
        """
        if not isinstance(value, dict):
            raise serializers.ValidationError("edited_json must be a dictionary")
        
        editable_elements = value.get('editable_elements', [])
        if not isinstance(editable_elements, list):
            raise serializers.ValidationError("editable_elements must be a list")
        
        # Validate each element has the required structure but be flexible with naming
        for element in editable_elements:
            if not isinstance(element, dict):
                raise serializers.ValidationError("Each element must be a dictionary")
            
            # Check for required fields but allow either name format
            if not ('type' in element or 'element_type' in element):
                raise serializers.ValidationError("Element must have 'type' field")
            
            if not isinstance(element.get('box', {}), dict):
                raise serializers.ValidationError("Element must have valid 'box' field")
                
            if not isinstance(element.get('content', {}), dict):
                raise serializers.ValidationError("Element must have valid 'content' field")
                
            if not isinstance(element.get('style', {}), dict):
                raise serializers.ValidationError("Element must have valid 'style' field")
        
        return value

class TemplateElementSerializer(serializers.ModelSerializer):
    class Meta:
        model = TemplateElement
        fields = "__all__"

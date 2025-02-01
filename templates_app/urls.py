from django.urls import path
from .views import TemplateListView, TemplateDetailView, TemplateEditCreateView, generate_template_preview

urlpatterns = [
    path("templates/", TemplateListView.as_view(), name="template-list"),
    path("templates/<int:pk>/", TemplateDetailView.as_view(), name="template-detail"),
    path("templates/edit/", TemplateEditCreateView.as_view(), name="template-edit"),
    path('preview/<int:template_id>/', generate_template_preview, name="template-preview"),
]

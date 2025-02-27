# Generated by Django 5.1.5 on 2025-01-31 10:46

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('templates_app', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='template',
            name='editable_json',
            field=models.JSONField(default=dict),
        ),
        migrations.AddField(
            model_name='template',
            name='preview_image',
            field=models.ImageField(blank=True, null=True, upload_to='previews/'),
        ),
    ]

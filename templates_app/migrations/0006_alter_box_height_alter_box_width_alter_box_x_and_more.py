# Generated by Django 5.1.5 on 2025-02-01 14:00

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('templates_app', '0005_box_templateelement'),
    ]

    operations = [
        migrations.AlterField(
            model_name='box',
            name='height',
            field=models.IntegerField(),
        ),
        migrations.AlterField(
            model_name='box',
            name='width',
            field=models.IntegerField(),
        ),
        migrations.AlterField(
            model_name='box',
            name='x',
            field=models.IntegerField(),
        ),
        migrations.AlterField(
            model_name='box',
            name='y',
            field=models.IntegerField(),
        ),
    ]

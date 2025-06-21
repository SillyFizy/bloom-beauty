from django.db import models
from django.core.validators import RegexValidator

class NavigationCategory(models.Model):
    """
    Model for managing navigation categories in the home screen
    (EYES, FACE, LIPS, SKIN, BODY, etc.)
    """
    name = models.CharField(
        max_length=50,
        unique=True,
        help_text="Display name for the category (e.g., 'EYES', 'FACE')"
    )
    value = models.CharField(
        max_length=50,
        unique=True,
        validators=[
            RegexValidator(
                regex=r'^[a-z_]+$',
                message='Value must be lowercase letters and underscores only'
            )
        ],
        help_text="Internal value for filtering (e.g., 'eyes', 'face')"
    )
    icon = models.CharField(
        max_length=100,
        blank=True,
        help_text="Material Icon name (optional)"
    )
    description = models.TextField(
        blank=True,
        help_text="Description for this category"
    )
    keywords = models.TextField(
        help_text="Comma-separated keywords for product filtering (e.g., 'eye,mascara,shadow,liner')"
    )
    order = models.PositiveIntegerField(
        default=0,
        help_text="Display order (lower numbers appear first)"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this category is visible in the navigation"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'navigation_categories'
        ordering = ['order', 'name']
        verbose_name = 'Navigation Category'
        verbose_name_plural = 'Navigation Categories'

    def __str__(self):
        return f"{self.name} ({self.value})"

    def get_keywords_list(self):
        """Return keywords as a list"""
        if not self.keywords:
            return []
        return [keyword.strip().lower() for keyword in self.keywords.split(',') if keyword.strip()]

    def save(self, *args, **kwargs):
        # Ensure value is lowercase
        self.value = self.value.lower()
        super().save(*args, **kwargs) 
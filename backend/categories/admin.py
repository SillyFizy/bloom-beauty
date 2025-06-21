from django.contrib import admin
from django.utils.html import format_html
from .models import NavigationCategory

@admin.register(NavigationCategory)
class NavigationCategoryAdmin(admin.ModelAdmin):
    list_display = [
        'name', 
        'value', 
        'order', 
        'is_active',
        'is_active_badge',
        'keyword_count',
        'created_at'
    ]
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'value', 'keywords']
    list_editable = ['order', 'is_active']
    ordering = ['order', 'name']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'value', 'icon', 'description')
        }),
        ('Filtering & Display', {
            'fields': ('keywords', 'order', 'is_active')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )

    def is_active_badge(self, obj):
        if obj.is_active:
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Active</span>'
            )
        return format_html(
            '<span style="color: red; font-weight: bold;">✗ Inactive</span>'
        )
    is_active_badge.short_description = 'Status'

    def keyword_count(self, obj):
        keywords = obj.get_keywords_list()
        return f"{len(keywords)} keywords"
    keyword_count.short_description = 'Keywords'

    def get_queryset(self, request):
        return super().get_queryset(request)

    class Media:
        css = {
            'all': ('admin/css/custom_admin.css',)
        }

# Custom admin actions
def activate_categories(modeladmin, request, queryset):
    queryset.update(is_active=True)
    modeladmin.message_user(request, f"Successfully activated {queryset.count()} categories.")
activate_categories.short_description = "Activate selected categories"

def deactivate_categories(modeladmin, request, queryset):
    queryset.update(is_active=False)
    modeladmin.message_user(request, f"Successfully deactivated {queryset.count()} categories.")
deactivate_categories.short_description = "Deactivate selected categories"

NavigationCategoryAdmin.actions = [activate_categories, deactivate_categories] 
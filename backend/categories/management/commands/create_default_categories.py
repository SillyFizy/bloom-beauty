from django.core.management.base import BaseCommand
from categories.models import NavigationCategory

class Command(BaseCommand):
    help = 'Create default navigation categories for the home screen'

    def handle(self, *args, **options):
        # Default categories (excluding HOME which is hardcoded in frontend)
        default_categories = [
            {
                'name': 'EYES',
                'value': 'eyes',
                'icon': 'visibility',
                'description': 'Eye makeup and care products',
                'keywords': 'eye,mascara,shadow,liner,eyebrow,lash,eyeshadow,eyeliner',
                'order': 1
            },
            {
                'name': 'FACE',
                'value': 'face',
                'icon': 'face',
                'description': 'Face makeup and foundation products',
                'keywords': 'foundation,powder,concealer,blush,bronzer,face,contour,highlight',
                'order': 2
            },
            {
                'name': 'LIPS',
                'value': 'lips',
                'icon': 'lips',
                'description': 'Lip care and lip makeup products',
                'keywords': 'lip,gloss,balm,lipstick,lipgloss,lip liner,matte,liquid',
                'order': 3
            },
            {
                'name': 'SKIN',
                'value': 'skin',
                'icon': 'spa',
                'description': 'Skincare and skin treatment products',
                'keywords': 'serum,moisturizer,cleanser,cream,skin,skincare,toner,exfoliate',
                'order': 4
            },
            {
                'name': 'BODY',
                'value': 'body',
                'icon': 'person',
                'description': 'Body care and body makeup products',
                'keywords': 'body,lotion,scrub,bath,shower,body wash,body cream,oil',
                'order': 5
            }
        ]

        created_count = 0
        updated_count = 0

        for category_data in default_categories:
            category, created = NavigationCategory.objects.get_or_create(
                value=category_data['value'],
                defaults=category_data
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created category: {category.name}')
                )
            else:
                # Update existing category with new data
                for key, value in category_data.items():
                    if key != 'value':  # Don't update the value field
                        setattr(category, key, value)
                category.save()
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'Updated category: {category.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\nSuccessfully processed {len(default_categories)} categories:'
            )
        )
        self.stdout.write(f'  - Created: {created_count}')
        self.stdout.write(f'  - Updated: {updated_count}')
        
        # Show all active categories
        active_categories = NavigationCategory.objects.filter(is_active=True).order_by('order')
        self.stdout.write(f'\nActive categories ({active_categories.count()}):')
        for cat in active_categories:
            status = "✓" if cat.is_active else "✗"
            self.stdout.write(f'  {status} {cat.order}. {cat.name} ({cat.value})') 
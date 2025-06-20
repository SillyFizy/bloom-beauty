from django.core.management.base import BaseCommand
from products.models import Product

class Command(BaseCommand):
    help = 'Update all product descriptions with professional Arabic descriptions'

    def handle(self, *args, **options):
        # High-quality Arabic product descriptions for beauty products
        descriptions = {
            # Foundation Products
            'flawless-stay-liquid-foundation': 'كريم أساس سائل فائق الثبات يوفر تغطية مثالية تدوم طوال اليوم. تركيبة مقاومة للماء والعرق تمنحك بشرة ناعمة ومتجانسة بلمسة نهائية طبيعية. مناسب لجميع أنواع البشرة، يخفي العيوب ويوحد لون البشرة بشكل احترافي.',
            
            # Blush Products
            'flawless-stay-liquid-blush-cheeked-up-wands': 'أحمر خدود سائل بتركيبة مبتكرة يمنح خديك إشراقة طبيعية وحيوية. سهل التطبيق والمزج، يدوم لساعات طويلة دون تلطخ. يأتي بألوان متدرجة تناسب جميع درجات البشرة لإطلالة منعشة وجذابة.',
            
            # Lip Products
            'plump-pout-plumping-gloss-stick': 'ملمع شفاه مكثف يمنح شفتيك حجماً وامتلاءً طبيعياً مع لمعة جذابة. تركيبة مرطبة غنية بالفيتامينات تغذي الشفاه وتحميها من الجفاف. يوفر لوناً شفافاً جميلاً مع تأثير مكثف فوري.',
            
            'nude-x-soft-matte-lipstick': 'أحمر شفاه مطفي بتركيبة كريمية ناعمة يمنح شفتيك لوناً عميقاً وثباتاً استثنائياً. مجموعة ألوان نود عصرية تناسب الإطلالات اليومية والمسائية. تركيبة مرطبة لا تسبب جفاف الشفاه.',
            
            'balm-n-cute': 'بلسم شفاه مرطب بتركيبة طبيعية يعيد نعومة ونضارة شفتيك. غني بالزيوت المغذية والفيتامينات، يحمي من التشقق والجفاف. مثالي للاستخدام اليومي تحت أحمر الشفاه أو منفرداً للحصول على شفاه صحية ونضرة.',
            
            # Eye Products
            'glamour-eyes-eyeshadow-palette': 'باليت ظلال عيون فاخرة تضم مجموعة متنوعة من الألوان المتناسقة لإطلالات عيون مذهلة. تركيبة مخملية سهلة المزج، ألوان مشبعة تدوم طويلاً. مناسبة للمكياج النهاري والمسائي الدرامي.',
            
            'precision-eyeliner-pen': 'قلم كحل دقيق بتركيبة مقاومة للماء يمنحك خطوطاً واضحة ومحددة. سهل الاستخدام برأس مدبب للدقة المثالية، يدوم طوال اليوم دون تلطخ. مثالي لرسم الآي لاينر الكلاسيكي أو العيون المجنحة.',
            
            'volume-boost-mascara': 'ماسكارا مكثفة للرموش تمنح حجماً وطولاً استثنائياً. تركيبة غنية لا تتكتل، تفصل كل رمش على حدة لإطلالة طبيعية وجذابة. مقاومة للماء والرطوبة، تدوم طوال اليوم دون تساقط.',
            
            # Skincare Products
            'hydrating-face-serum': 'سيروم مرطب مكثف للوجه بتركيبة متقدمة تعيد الحيوية والنضارة لبشرتك. غني بحمض الهيالورونيك والفيتامينات المغذية، يرطب البشرة بعمق ويقلل من ظهور الخطوط الدقيقة. مناسب لجميع أنواع البشرة.',
            
            'brightening-vitamin-c-cream': 'كريم مشرق بفيتامين سي يوحد لون البشرة ويقلل من التصبغات والبقع الداكنة. تركيبة خفيفة سريعة الامتصاص تحفز تجديد الخلايا وتمنح البشرة إشراقة طبيعية. يحتوي على مضادات الأكسدة لحماية البشرة من العوامل البيئية.',
            
            'anti-aging-night-cream': 'كريم ليلي مضاد للشيخوخة بتركيبة مكثفة تعمل أثناء النوم لتجديد البشرة. يحتوي على الكولاجين والببتيدات المحفزة لشد البشرة وتقليل التجاعيد. يوقظ البشرة نضرة ومشرقة في الصباح.',
            
            # Face Products
            'contour-highlight-palette': 'باليت كونتور وهايلايت احترافية لنحت وإبراز ملامح الوجه. تحتوي على درجات متنوعة للتظليل والإضاءة، تركيبة قابلة للمزج بسهولة. تمنحك إطلالة منحوتة وبارزة كالمحترفين.',
            
            'setting-powder-translucent': 'بودرة تثبيت شفافة تحافظ على مكياجك طوال اليوم. تركيبة خفيفة تمتص الزيوت الزائدة دون إضافة لون، تمنح البشرة لمسة نهائية مطفية طبيعية. مناسبة لجميع درجات البشرة.',
            
            'primer-smoothing-base': 'برايمر ناعم يهيئ البشرة لتطبيق المكياج المثالي. يملأ المسام ويخفي الخطوط الدقيقة، يطيل ثبات المكياج ويمنحه مظهراً احترافياً. تركيبة خفيفة تناسب جميع أنواع البشرة.',
            
            # Nail Products
            'long-lasting-nail-polish': 'طلاء أظافر طويل الأمد بألوان زاهية وثبات استثنائي. تركيبة سريعة الجفاف تمنح الأظافر لمعة جميلة تدوم لأسابيع. سهل التطبيق بفرشاة عريضة للحصول على طبقة متجانسة.',
            
            'nail-strengthening-treatment': 'علاج مقوي للأظافر يحتوي على البروتينات والفيتامينات المغذية. يقوي الأظافر الضعيفة والمتكسرة، يمنع التقشر ويحفز النمو الصحي. يُستخدم كقاعدة تحت طلاء الأظافر أو منفرداً.',
            
            # Hair Products
            'nourishing-hair-mask': 'ماسك مغذي للشعر بتركيبة طبيعية غنية بالزيوت والبروتينات. يرطب الشعر الجاف والتالف، يعيد اللمعة والنعومة الطبيعية. يقوي الشعر من الجذور حتى الأطراف لشعر صحي وحيوي.',
            
            'volumizing-dry-shampoo': 'شامبو جاف مكثف ينظف الشعر ويمنحه حجماً فورياً دون الحاجة للماء. يمتص الزيوت الزائدة وينعش فروة الرأس، يترك الشعر نظيفاً ومنتعشاً. مثالي للاستخدام بين غسلات الشعر.',
            
            # Body Products
            'moisturizing-body-lotion': 'لوشن مرطب للجسم بتركيبة غنية تغذي البشرة وتحميها من الجفاف. يحتوي على زبدة الشيا والجلسرين المرطب، يترك البشرة ناعمة ومرنة طوال اليوم. عطر خفيف ومنعش.',
            
            'exfoliating-body-scrub': 'مقشر طبيعي للجسم يزيل خلايا الجلد الميتة ويحفز تجديد البشرة. يحتوي على حبيبات طبيعية ناعمة وزيوت مغذية، يترك البشرة ناعمة ومشرقة. يحسن ملمس البشرة ويحضرها لامتصاص المرطبات.',
            
            # Fragrance Products
            'signature-perfume-50ml': 'عطر مميز بتركيبة فاخرة تجمع بين النوتات الزهرية والخشبية. عطر طويل الأمد يناسب جميع المناسبات، يترك أثراً جذاباً ومتميزاً. تركيبة متوازنة تناسب الشخصية العصرية والأنيقة.',
            
            'body-mist-refreshing': 'رذاذ منعش للجسم بعطر خفيف ومنعش يدوم طوال اليوم. مثالي للاستخدام اليومي، يترك البشرة معطرة ومنتعشة. تركيبة خفيفة لا تسبب حساسية، مناسبة للاستخدام المتكرر.',
        }
        
        # Get all products
        products = Product.objects.all()
        updated_count = 0
        
        self.stdout.write(f"Found {products.count()} products to update...")
        
        for product in products:
            # Check if we have a specific description for this product
            if product.slug in descriptions:
                product.description = descriptions[product.slug]
                product.save()
                updated_count += 1
                self.stdout.write(f"✅ Updated: {product.name} ({product.slug})")
            else:
                # Generate a generic but professional Arabic description based on product name
                generic_description = self.generate_generic_description(product.name, product.category.name if product.category else 'منتج تجميل')
                product.description = generic_description
                product.save()
                updated_count += 1
                self.stdout.write(f"🔄 Generated description for: {product.name} ({product.slug})")
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully updated {updated_count} product descriptions in Arabic!')
        )
    
    def generate_generic_description(self, product_name, category_name):
        """Generate a generic professional Arabic description for products not in the specific list"""
        
        # Base templates for different product categories
        templates = {
            'foundation': 'كريم أساس عالي الجودة يوفر تغطية مثالية ونتائج احترافية. تركيبة متقدمة تدوم طوال اليوم وتناسب جميع أنواع البشرة. يمنح بشرتك مظهراً طبيعياً وناعماً مع إخفاء العيوب بشكل مثالي.',
            'lipstick': 'أحمر شفاه فاخر بتركيبة كريمية غنية تمنح شفتيك لوناً جميلاً وثباتاً طويل الأمد. يرطب الشفاه ويحميها من الجفاف، مع مجموعة ألوان عصرية تناسب جميع الإطلالات والمناسبات.',
            'mascara': 'ماسكارا متطورة تمنح رموشك حجماً وطولاً استثنائياً. تركيبة لا تتكتل وتفصل كل رمش بدقة، مقاومة للماء وتدوم طوال اليوم. تمنحك إطلالة عيون جذابة وطبيعية.',
            'eyeshadow': 'ظلال عيون بألوان مشبعة وتركيبة ناعمة سهلة المزج. تدوم طويلاً دون تساقط وتمنحك إطلالات عيون متنوعة من الطبيعية إلى الدرامية. مناسبة للمكياج النهاري والمسائي.',
            'blush': 'أحمر خدود يمنح وجهك إشراقة طبيعية وحيوية. تركيبة قابلة للمزج بسهولة تدوم لساعات طويلة، متوفر بألوان متدرجة تناسب جميع درجات البشرة لإطلالة منعشة وجذابة.',
            'powder': 'بودرة فاخرة بتركيبة ناعمة تمنح البشرة لمسة نهائية مثالية. تثبت المكياج وتتحكم في اللمعة الزائدة، تناسب جميع أنواع البشرة وتمنحها مظهراً طبيعياً ومتجانساً.',
            'serum': 'سيروم متطور بتركيبة مكثفة يستهدف احتياجات بشرتك الخاصة. غني بالمكونات الفعالة والفيتامينات، يحسن ملمس البشرة ونضارتها. سريع الامتصاص ومناسب للاستخدام اليومي.',
            'cream': 'كريم مرطب بتركيبة غنية ومغذية تعتني ببشرتك وتحميها. يحتوي على مكونات طبيعية فعالة تحافظ على نعومة البشرة ونضارتها. مناسب للاستخدام اليومي صباحاً ومساءً.',
            'perfume': 'عطر فاخر بتركيبة مميزة تجمع بين أفضل النوتات العطرية. عطر طويل الأمد يناسب شخصيتك المتميزة، يترك انطباعاً جذاباً ولا يُنسى. مثالي لجميع المناسبات والأوقات.',
            'nail': 'منتج عناية بالأظافر عالي الجودة يمنحك نتائج احترافية في المنزل. تركيبة متطورة تقوي الأظافر وتحميها، سهل الاستخدام ويدوم طويلاً. يمنحك أظافر جميلة وصحية.',
        }
        
        # Try to match product category or name with templates
        product_lower = product_name.lower()
        category_lower = category_name.lower()
        
        if 'foundation' in product_lower or 'أساس' in product_lower:
            return templates['foundation']
        elif 'lipstick' in product_lower or 'شفاه' in product_lower or 'lip' in product_lower:
            return templates['lipstick']
        elif 'mascara' in product_lower or 'ماسكارا' in product_lower:
            return templates['mascara']
        elif 'eyeshadow' in product_lower or 'shadow' in product_lower or 'ظلال' in product_lower:
            return templates['eyeshadow']
        elif 'blush' in product_lower or 'خدود' in product_lower:
            return templates['blush']
        elif 'powder' in product_lower or 'بودرة' in product_lower:
            return templates['powder']
        elif 'serum' in product_lower or 'سيروم' in product_lower:
            return templates['serum']
        elif 'cream' in product_lower or 'كريم' in product_lower:
            return templates['cream']
        elif 'perfume' in product_lower or 'عطر' in product_lower or 'fragrance' in product_lower:
            return templates['perfume']
        elif 'nail' in product_lower or 'أظافر' in product_lower:
            return templates['nail']
        else:
            # Generic beauty product description
            return f'منتج تجميل عالي الجودة من مجموعة {category_name} يوفر نتائج احترافية ومتميزة. تركيبة متطورة تناسب احتياجاتك اليومية وتمنحك إطلالة جذابة وطبيعية. سهل الاستخدام ومناسب لجميع أنواع البشرة، يدوم طويلاً ويحقق النتائج المرغوبة.' 
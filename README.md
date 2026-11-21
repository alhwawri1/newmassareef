# Masareef | مصاريف — مشروع iOS ووجيت وCodemagic

هذا المشروع جاهز للرفع على **GitHub** وبناء ملف **Unsigned `.ipa`** عبر **Codemagic**، ويتضمن:
1. تطبيق الويب الكامل (`www/index.html`) مع حفظ محلي `Offline` ودعم العربية والإنجليزية والوضع الليلي والنهاري.
2. أيقونات التطبيق المولّدة من صورتك (`icon-maskable-512x512.png`) داخل `www/assets/icons/` و`ios/App/App/Assets.xcassets/AppIcon.appiconset/` و`ios/App/MasareefWidget/Assets.xcassets/AppIcon.appiconset/`.
3. وجيتات iOS عبر **WidgetKit + SwiftUI** (`ios/App/MasareefWidget/MasareefWidget.swift`):
   - **وجيت الميزانية والملخص الشهري** (`systemSmall` و`systemMedium`): يعرض مصروف الشهر، النسبة، المتبقي أو التجاوز، وزر إضافة سريع (`masareef://add-expense`).
   - **وجيت قائمة المشتريات** (`systemMedium` و`systemLarge`): يعرض اسم القائمة النشطة وعدد العناصر المتبقية وأول العناصر المطلوبة.
   - **وجيت شاشة القفل** (`accessoryCircular` و`accessoryRectangular`).
4. ملف إعداد البناء التلقائي على Codemagic (`codemagic.yaml`) وسكربت ربط الوجيت بمشروع Xcode (`scripts/setup-xcode-widget.js`).

## خطوات الرفع والبناء
1. ارفع مجلد المشروع كاملاً إلى مستودع جديد في **GitHub**.
2. اربط المستودع في **Codemagic** واختر سير العمل `masareef-unsigned-ipa`.
3. بعد نجاح البناء، حمّل ملف `Masareef-unsigned.ipa` من قسم **Artifacts** وثبّته على الآيفون عبر أداتك المفضلة (مثل Sideloadly).

Developed by **Al Hawari Al Naabi**.

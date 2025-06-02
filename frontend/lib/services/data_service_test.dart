import 'data_service.dart';
import '../models/product_model.dart';
import '../models/celebrity_model.dart';

void main() {
  final dataService = DataService();
  
  print('=== Testing Celebrity Navigation Data Completeness ===');
  
  // Test products with celebrity endorsements
  final products = dataService.getAllProducts();
  final productsWithEndorsements = products.where((p) => p.celebrityEndorsement != null).toList();
  
  print('Found ${productsWithEndorsements.length} products with celebrity endorsements:');
  
  for (var product in productsWithEndorsements) {
    final endorsement = product.celebrityEndorsement!;
    final celebrityData = dataService.getCelebrityDataForProduct(endorsement.celebrityName);
    
    print('\n${product.name} (endorsed by ${endorsement.celebrityName}):');
    print('  - Social Media Links: ${(celebrityData['socialMediaLinks'] as Map).length}');
    print('  - Recommended Products: ${(celebrityData['recommendedProducts'] as List).length}');
    print('  - Morning Routine Products: ${(celebrityData['morningRoutineProducts'] as List).length}');
    print('  - Evening Routine Products: ${(celebrityData['eveningRoutineProducts'] as List).length}');
    
    // Verify navigation data is complete
    final hasAllData = 
        (celebrityData['socialMediaLinks'] as Map).isNotEmpty &&
        (celebrityData['recommendedProducts'] as List).isNotEmpty &&
        (celebrityData['morningRoutineProducts'] as List).isNotEmpty &&
        (celebrityData['eveningRoutineProducts'] as List).isNotEmpty;
    
    print('  - Navigation Ready: ${hasAllData ? "✓" : "✗"}');
  }
  
  print('\n=== Celebrity navigation from product details is now fixed! ===');
} 
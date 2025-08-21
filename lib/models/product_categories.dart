class ProductCategories {
  static const Map<String, List<String>> categories = {
    'Bags & Packaging': [
      'Paper bag',
      'Pouch',
      '6x9 pouch',
      'Roll',
      'Parcel bag',
      'Handle bag',
      'Kanda-limbu bag',
      'C Bag',
      'Chutney bag',
      'Garbage bag big',
      'Garbage bag small',
      'Garbage bag green',
      'Garbage bag black',
      'Garbage bag grey big',
    ],
    
    'Containers & Disposables': [
      'Pav-Bhaji container',
      'Biryani container',
      'Big container',
      'Small container',
      'Silver container 950ml',
      'Silver container 450 ml',
      'Silver container big',
      'Chutney box',
      'Ice-Cream cup',
      'Glass',
      '300ml glass',
      'Water glass',
      'Juice glass',
      'Spoon',
    ],
    
    'Cleaning Supplies': [
      'White phenyl',
      'White phynel',
      'Phenyl',
      'Pheinyl',
      'Glass cleaner',
      'Glass Cleaner',
      'Hand wash',
      'Hand Wash',
      'Handwash',
      'Clean foil',
      'Clean wrap',
      'cleaning foil',
      'Chain foil',
      'Clean napkin',
      'Clean Napkin',
      'Napkin',
      'Table duster',
      'Table Duster',
      'Ladi duster',
      'Tissue box',
      'Tissue Box',
      'Tssue box',
      'Fluid gel',
      'Scotch brite',
      'Scrotch brite',
      'Sponge',
      'Mop set',
      'mop',
      'Wipper',
      'Wipper set',
      'Wiper set',
      'Zadu',
      'Air freshener',
      'Air freshener liquid',
      'Godrej liquid',
      'Caustic Soda',
      'Nirma',
    ],
    
    'Safety & Protection': [
      'Gloves',
      'Gloves oil chargs',
      'Gloves drawings',
      'silicon gloves',
      'cotton gloves Heavy Duty',
      'Arm guard',
      'Sefty goggle',
      'Cap',
    ],
    
    'Office Supplies': [
      'A4 rim',
      'Box file',
      'Pane bore',
      'High ighter',
      'Taps',
      'Stier',
      'White board marker',
      'White board marker black',
      'white board marker',
      'Toilet roll',
      'Pencil dell small',
      'Pencil calling',
    ],
    
    'Food Service Items': [
      'Straw',
      'Toothpice',
      'Chai patti',
      'Pop-up',
      'Pop-up bor',
    ],
    
    'Miscellaneous': [
      'Ghasni',
      'Indonesian Kharata',
      'Supli',
      'fan',
      'oil',
      'Air',
    ],
  };

  static String getCategoryForProduct(String productName) {
    for (final entry in categories.entries) {
      if (entry.value.any((product) => 
          product.toLowerCase() == productName.toLowerCase())) {
        return entry.key;
      }
    }
    return 'Miscellaneous';
  }

  static List<String> getAllCategories() {
    return categories.keys.toList();
  }

  static List<String> getProductsInCategory(String category) {
    return categories[category] ?? [];
  }
}
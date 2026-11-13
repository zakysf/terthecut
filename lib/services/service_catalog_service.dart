import '../config/supabase_config.dart';
import '../models/service_item.dart';

class ServiceCatalogService {
  static final List<ServiceCategory> _seedCategories = [
    ServiceCategory(
      id: 'cat-1',
      name: 'Hair Cut',
      description: 'Layanan potong rambut presisi sesuai bentuk kepala dan karakter Anda.',
      sortOrder: 1,
    ),
    ServiceCategory(
      id: 'cat-2',
      name: 'Face & Hair Care Treatment',
      description: 'Perawatan intensif kulit kepala dan rambut agar sehat berkilau.',
      sortOrder: 2,
    ),
    ServiceCategory(
      id: 'cat-3',
      name: 'Texture Services',
      description: 'Menciptakan volume dan tekstur rambut melalui teknik perming modern.',
      sortOrder: 3,
    ),
  ];

  static final List<ServiceItem> _seedServices = [
    // Hair Cut (1 Jam)
    ServiceItem(
      id: 'svc-1',
      categoryId: 'cat-1',
      name: 'Premium Haircut',
      description: 'Potong rambut, cuci rambut, pijat relaksasi kepala, tonic & styling.',
      price: 35000,
      durationHours: 1,
      points: 10,
      sortOrder: 1,
    ),
    ServiceItem(
      id: 'svc-2',
      categoryId: 'cat-1',
      name: 'Signature VIP Haircut',
      description: 'Potong rambut VIP, cuci premium, hot towel, facial wash & pomade styling.',
      price: 65000,
      durationHours: 1,
      points: 10,
      sortOrder: 2,
    ),

    // Face & Hair Care Treatment (1 Jam)
    ServiceItem(
      id: 'svc-3',
      categoryId: 'cat-2',
      name: 'Facial Treatment',
      description: 'Pembersihan pori-pori wajah, scrub alami, dan masker penyegar.',
      price: 55000,
      durationHours: 1,
      points: 10,
      sortOrder: 1,
    ),
    ServiceItem(
      id: 'svc-4',
      categoryId: 'cat-2',
      name: 'Hair Mask - Short Hair',
      description: 'Nutrisi ekstra untuk mengatasi rambut kering dan kusam.',
      price: 35000,
      durationHours: 1,
      points: 10,
      sortOrder: 2,
    ),
    ServiceItem(
      id: 'svc-5',
      categoryId: 'cat-2',
      name: 'Creambath - Short Hair',
      description: 'Krim perawatan rambut pendek dilengkapi pijatan pundak & leher.',
      price: 50000,
      durationHours: 1,
      points: 10,
      sortOrder: 3,
    ),
    ServiceItem(
      id: 'svc-6',
      categoryId: 'cat-2',
      name: 'Creambath - Medium Hair',
      description: 'Perawatan menyeluruh rambut sedang dengan masker krim aromaterapi.',
      price: 60000,
      durationHours: 1,
      points: 10,
      sortOrder: 4,
    ),

    // Texture Services (1, 2, atau 3 Jam)
    ServiceItem(
      id: 'svc-7',
      categoryId: 'cat-3',
      name: 'Down Perm - Short Hair',
      description: 'Merapikan bagian samping rambut yang jigrak agar turun rapi alami.',
      price: 150000,
      durationHours: 1,
      points: 25,
      sortOrder: 1,
    ),
    ServiceItem(
      id: 'svc-8',
      categoryId: 'cat-3',
      name: 'Bye-Bye Pomade - Normal Hair',
      description: 'Treatment deep cleaning untuk mengangkat residu produk minyak/pomade.',
      price: 125000,
      durationHours: 1,
      points: 25,
      sortOrder: 2,
    ),
    ServiceItem(
      id: 'svc-9',
      categoryId: 'cat-3',
      name: 'Texture Perm Wavy (Men) - Short Hair',
      description: 'Keriting bergelombang santai natural gaya Korea untuk rambut pendek.',
      price: 200000,
      durationHours: 2,
      audience: 'Pria',
      points: 25,
      sortOrder: 3,
    ),
    ServiceItem(
      id: 'svc-10',
      categoryId: 'cat-3',
      name: 'Texture Perm Wavy (Men) - Medium Hair',
      description: 'Gelombang rambut bertekstur modern untuk rambut sedang.',
      price: 300000,
      durationHours: 2,
      audience: 'Pria',
      points: 50,
      sortOrder: 4,
    ),
    ServiceItem(
      id: 'svc-11',
      categoryId: 'cat-3',
      name: 'Texture Perm Wavy (Men) - Long Hair',
      description: 'Gelombang penuh elegan untuk rambut pria panjang.',
      price: 500000,
      durationHours: 2,
      audience: 'Pria',
      points: 50,
      sortOrder: 5,
    ),
    ServiceItem(
      id: 'svc-12',
      categoryId: 'cat-3',
      name: 'Design Perm - 1.0',
      description: 'Perm desain dasar untuk memberikan volume pada akar rambut.',
      price: 350000,
      durationHours: 2,
      points: 50,
      sortOrder: 6,
    ),
    ServiceItem(
      id: 'svc-13',
      categoryId: 'cat-3',
      name: 'Design Perm - 2.0',
      description: 'Perm kombinasi volume dan tekstur gelombang khusus.',
      price: 500000,
      durationHours: 2,
      points: 50,
      sortOrder: 7,
    ),
    ServiceItem(
      id: 'svc-14',
      categoryId: 'cat-3',
      name: 'Texture Perm (Women) - Short Hair',
      description: 'Perm tekstur lembut untuk rambut pendek wanita.',
      price: 300000,
      durationHours: 2,
      audience: 'Wanita',
      points: 50,
      sortOrder: 8,
    ),
    ServiceItem(
      id: 'svc-15',
      categoryId: 'cat-3',
      name: 'Texture Perm (Women) - Medium Hair',
      description: 'Pengeritingan intensif rambut sedang wanita agar lebih tebal bervolume.',
      price: 400000,
      durationHours: 3,
      audience: 'Wanita',
      points: 50,
      sortOrder: 9,
    ),
    ServiceItem(
      id: 'svc-16',
      categoryId: 'cat-3',
      name: 'Texture Perm Curly (Men) - Short Hair',
      description: 'Keriting spiral rapat untuk pria berambut pendek.',
      price: 200000,
      durationHours: 2,
      audience: 'Pria',
      points: 25,
      sortOrder: 10,
    ),
    ServiceItem(
      id: 'svc-17',
      categoryId: 'cat-3',
      name: 'Texture Perm Curly (Men) - Medium Hair',
      description: 'Curly afro / modern tight curls untuk rambut pria ukuran sedang.',
      price: 300000,
      durationHours: 3,
      audience: 'Pria',
      points: 50,
      sortOrder: 11,
    ),
    ServiceItem(
      id: 'svc-18',
      categoryId: 'cat-3',
      name: 'Texture Perm Curly (Men) - Long Hair',
      description: 'Curly berkarakter tegas dan tahan lama untuk rambut panjang pria.',
      price: 500000,
      durationHours: 3,
      audience: 'Pria',
      points: 50,
      sortOrder: 12,
    ),
  ];

  Future<List<ServiceCategory>> fetchCategories() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client
            .from('service_categories')
            .select()
            .order('sort_order', ascending: true);
        return (data as List).map((e) => ServiceCategory.fromJson(e)).toList();
      } catch (e) {
        return _seedCategories;
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _seedCategories;
  }

  Future<List<ServiceItem>> fetchServices() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client
            .from('services')
            .select()
            .order('sort_order', ascending: true);
        return (data as List).map((e) => ServiceItem.fromJson(e)).toList();
      } catch (e) {
        return _seedServices;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return _seedServices;
  }
}


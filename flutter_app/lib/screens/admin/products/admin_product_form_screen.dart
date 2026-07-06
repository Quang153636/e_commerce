import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../admin_theme.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Product? product; // null = thêm mới, có giá trị = sửa
  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imagesCtrl = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isActive = true;
  bool _loading = false;
  bool _loadingCats = true;

  // Variant management
  List<ProductVariantType> _variantTypes = [];
  List<ProductVariant> _variants = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEdit) _fillForm(widget.product!);
  }

  void _fillForm(Product p) {
    _nameCtrl.text      = p.name;
    _descCtrl.text      = p.description ?? '';
    _priceCtrl.text     = p.price.toStringAsFixed(0);
    _salePriceCtrl.text = p.salePrice?.toStringAsFixed(0) ?? '';
    _stockCtrl.text     = p.stock.toString();
    _imagesCtrl.text    = p.images.join('\n');
    _selectedCategoryId = p.categoryId;
    _isActive           = p.isActive;
    
    // Clone variant types and variants
    _variantTypes = p.variantTypes.map((vt) => ProductVariantType(
      id: vt.id,
      productId: vt.productId,
      name: vt.name,
      options: List.from(vt.options),
    )).toList();
    
    _variants = p.variants.map((v) => ProductVariant(
      id: v.id,
      productId: v.productId,
      attributes: Map<String, String>.from(v.attributes),
      price: v.price,
      stock: v.stock,
      sku: v.sku,
    )).toList();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await AdminService.getCategories();
      if (_selectedCategoryId == null && _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
    } finally {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      Fluttertoast.showToast(msg: 'Vui lòng chọn danh mục');
      return;
    }

    setState(() => _loading = true);

    final images = _imagesCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Prepare variant types data
    final variantTypesData = _variantTypes.map((vt) => {
      'id'      : vt.id,
      'name'    : vt.name,
      'options' : vt.options,
    }).toList();

    // Prepare variants data
    final variantsData = _variants.map((v) => {
      'id'          : v.id,
      'attributes'  : v.attributes,
      'price'       : v.price,
      'stock'       : v.stock,
      'sku'         : v.sku,
    }).toList();

    final data = {
      'category_id'   : _selectedCategoryId,
      'name'          : _nameCtrl.text.trim(),
      'description'   : _descCtrl.text.trim(),
      'price'         : double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'sale_price'    : _salePriceCtrl.text.trim().isEmpty ? null : double.tryParse(_salePriceCtrl.text.trim()),
      'stock'         : int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'images'        : images,
      'is_active'     : _isActive,
      'variant_types' : variantTypesData,
      'variants'      : variantsData,
    };

    try {
      if (_isEdit) {
        await AdminService.updateProduct(widget.product!.id, data);
        Fluttertoast.showToast(msg: 'Đã cập nhật sản phẩm!');
      } else {
        await AdminService.createProduct(data);
        Fluttertoast.showToast(msg: 'Đã thêm sản phẩm mới!');
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Variant Type Management ──────────────────────────────────
  void _addVariantType() {
    setState(() {
      _variantTypes.add(ProductVariantType(
        id: 0,
        productId: widget.product?.id ?? 0,
        name: '',
        options: [],
      ));
    });
  }

  void _removeVariantType(int index) {
    setState(() {
      _variantTypes.removeAt(index);
    });
  }

  void _updateVariantTypeName(int index, String name) {
    setState(() {
      _variantTypes[index] = ProductVariantType(
        id: _variantTypes[index].id,
        productId: _variantTypes[index].productId,
        name: name,
        options: _variantTypes[index].options,
      );
    });
  }

  void _addVariantOption(int typeIndex) {
    setState(() {
      _variantTypes[typeIndex].options.add('');
    });
  }

  void _updateVariantOption(int typeIndex, int optionIndex, String value) {
    setState(() {
      final newOptions = List<String>.from(_variantTypes[typeIndex].options);
      newOptions[optionIndex] = value;
      _variantTypes[typeIndex] = ProductVariantType(
        id: _variantTypes[typeIndex].id,
        productId: _variantTypes[typeIndex].productId,
        name: _variantTypes[typeIndex].name,
        options: newOptions,
      );
    });
  }

  void _removeVariantOption(int typeIndex, int optionIndex) {
    setState(() {
      final newOptions = List<String>.from(_variantTypes[typeIndex].options);
      newOptions.removeAt(optionIndex);
      _variantTypes[typeIndex] = ProductVariantType(
        id: _variantTypes[typeIndex].id,
        productId: _variantTypes[typeIndex].productId,
        name: _variantTypes[typeIndex].name,
        options: newOptions,
      );
    });
  }

  // ─── Variant Management ───────────────────────────────────────
  void _generateVariants() {
    // Generate all combinations from variant types
    final filteredTypes = _variantTypes.where((vt) => vt.name.isNotEmpty && vt.options.isNotEmpty).toList();
    
    if (filteredTypes.isEmpty) {
      setState(() {
        _variants = [];
      });
      return;
    }

    // Generate combinations
    List<Map<String, String>> combinations = [{}];
    for (final type in filteredTypes) {
      List<Map<String, String>> newCombinations = [];
      for (final combo in combinations) {
        for (final option in type.options) {
          newCombinations.add(Map<String, String>.from(combo)..[type.name] = option);
        }
      }
      combinations = newCombinations;
    }

    // Remove existing variants that match the same attributes
    final existingAttributes = _variants.map((v) => _attributesKey(v.attributes)).toSet();
    
    final newVariants = <ProductVariant>[];
    for (final attrs in combinations) {
      final key = _attributesKey(attrs);
      if (!existingAttributes.contains(key)) {
        // Get base price from current field
        final basePrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
        
        newVariants.add(ProductVariant(
          id: 0,
          productId: widget.product?.id ?? 0,
          attributes: attrs,
          price: basePrice,
          stock: 0,
          sku: null,
        ));
      }
    }

    setState(() {
      _variants.addAll(newVariants);
    });
  }

  String _attributesKey(Map<String, String> attrs) {
    final keys = attrs.keys.toList()..sort();
    return keys.map((k) => '$k:${attrs[k]}').join('|');
  }

  void _updateVariantPrice(int index, double? price) {
    setState(() {
      _variants[index] = ProductVariant(
        id: _variants[index].id,
        productId: _variants[index].productId,
        attributes: _variants[index].attributes,
        price: price,
        stock: _variants[index].stock,
        sku: _variants[index].sku,
      );
    });
  }

  void _updateVariantStock(int index, int stock) {
    setState(() {
      _variants[index] = ProductVariant(
        id: _variants[index].id,
        productId: _variants[index].productId,
        attributes: _variants[index].attributes,
        price: _variants[index].price,
        stock: stock,
        sku: _variants[index].sku,
      );
    });
  }

  void _updateVariantSku(int index, String? sku) {
    setState(() {
      _variants[index] = ProductVariant(
        id: _variants[index].id,
        productId: _variants[index].productId,
        attributes: _variants[index].attributes,
        price: _variants[index].price,
        stock: _variants[index].stock,
        sku: sku,
      );
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              _isEdit ? 'Lưu' : 'Thêm',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Thông tin cơ bản', [
                    // Danh mục
                    _buildLabel('Danh mục *'),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: _inputDeco('Chọn danh mục'),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Tên sản phẩm *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDeco('Nhập tên sản phẩm'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Mô tả'),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDeco('Mô tả chi tiết sản phẩm'),
                      maxLines: 3,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSection('Giá & Kho hàng', [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Giá gốc (đ) *'),
                              TextFormField(
                                controller: _priceCtrl,
                                decoration: _inputDeco('100000'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Bắt buộc';
                                  if (double.tryParse(v) == null) return 'Không hợp lệ';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Giá sale (đ)'),
                              TextFormField(
                                controller: _salePriceCtrl,
                                decoration: _inputDeco('Để trống nếu không'),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Số lượng kho *'),
                    TextFormField(
                      controller: _stockCtrl,
                      decoration: _inputDeco('0'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Bắt buộc';
                        if (int.tryParse(v) == null) return 'Phải là số nguyên';
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSection('Hình ảnh', [
                    _buildLabel('URL ảnh (mỗi link 1 dòng)'),
                    TextFormField(
                      controller: _imagesCtrl,
                      decoration: _inputDeco(
                          'https://example.com/image1.jpg\nhttps://example.com/image2.jpg'),
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    if (_imagesCtrl.text.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _imagesCtrl.text
                            .split('\n')
                            .where((e) => e.trim().isNotEmpty)
                            .take(3)
                            .map((url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url.trim(),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, size: 20),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSection('Loại sản phẩm', [
                    ...List.generate(_variantTypes.length, (index) {
                      final type = _variantTypes[index];
                      return Card(
                        color: Colors.grey[50],
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: type.name,
                                      decoration: _inputDeco('Tên loại (vd: Màu sắc, RAM)'),
                                      style: const TextStyle(fontSize: 13),
                                      onChanged: (v) => _updateVariantTypeName(index, v),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _removeVariantType(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(type.options.length, (optIndex) {
                                final option = type.options[optIndex];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: option,
                                        decoration: _inputDeco('Tùy chọn ${optIndex + 1}'),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (v) => _updateVariantOption(index, optIndex, v),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                      onPressed: () => _removeVariantOption(index, optIndex),
                                    ),
                                  ],
                                );
                              }),
                              TextButton.icon(
                                onPressed: () => _addVariantOption(index),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Thêm tùy chọn', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addVariantType,
                      icon: const Icon(Icons.add_box, size: 20),
                      label: const Text('Thêm loại sản phẩm'),
                      style: TextButton.styleFrom(foregroundColor: AdminColors.primary),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSection('Biến thể sản phẩm', [
                    if (_variantTypes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thêm loại sản phẩm và tùy chọn ở trên, sau đó nhấn "Tạo biến thể" để tạo các biến thể.',
                                style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _generateVariants();
                              Fluttertoast.showToast(msg: 'Đã tạo biến thể');
                            },
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Tạo biến thể'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_variants.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                          columns: const [
                            DataColumn(label: Text('Thuộc tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Giá (đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List.generate(_variants.length, (index) {
                            final variant = _variants[index];
                            final attrText = variant.attributes.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n');
                            
                            return DataRow(
                              cells: [
                                DataCell(Text(attrText, style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      initialValue: variant.price?.toStringAsFixed(0) ?? '',
                                      decoration: _inputDeco('Giá'),
                                      style: const TextStyle(fontSize: 12),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final price = double.tryParse(v);
                                        _updateVariantPrice(index, price);
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: variant.stock.toString(),
                                      decoration: _inputDeco('SL'),
                                      style: const TextStyle(fontSize: 12),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final stock = int.tryParse(v) ?? 0;
                                        _updateVariantStock(index, stock);
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      initialValue: variant.sku ?? '',
                                      decoration: _inputDeco('Mã SKU'),
                                      style: const TextStyle(fontSize: 12),
                                      onChanged: (v) => _updateVariantSku(index, v.isEmpty ? null : v),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () => _removeVariant(index),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Chưa có biến thể nào',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSection('Cài đặt', [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hiển thị sản phẩm', style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        _isActive ? 'Sản phẩm đang hiện trên app' : 'Sản phẩm đang bị ẩn',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isActive ? AdminColors.success : AdminColors.textGrey,
                        ),
                      ),
                      value: _isActive,
                      activeColor: AdminColors.accent,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AdminColors.textGrey, fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: AdminColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
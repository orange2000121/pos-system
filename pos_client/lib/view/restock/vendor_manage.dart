import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/vendor.dart';

class VendorManage extends StatefulWidget {
  const VendorManage({super.key});

  @override
  State<VendorManage> createState() => _VendorManageState();
}

class _VendorManageState extends State<VendorManage> {
  VendorProvider vendorProvider = VendorProvider();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('廠商管理'),
      ),
      body: FutureBuilder(
          future: vendorProvider.getAll(),
          builder: (context, snapshot) {
            return GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
              ),
              children: [
                Card(
                  child: SizedBox(
                    child: InkWell(
                      onTap: () async {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => VendorDetail(vendor: Vendor.empty(), isCreate: true))).then((value) {
                          if (value != null) {
                            setState(() {});
                          }
                        });
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          Text('新增廠商'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (snapshot.hasData)
                  ...snapshot.data!.map((e) {
                    return Card(
                      child: SizedBox(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => VendorDetail(vendor: e, isCreate: false))).then((value) {
                              if (value != null) {
                                setState(() {});
                              }
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(e.name),
                              Text(e.phone),
                              Text(e.address),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }),
    );
  }
}

class VendorDetail extends StatefulWidget {
  final Vendor vendor;
  final bool isCreate;
  const VendorDetail({
    super.key,
    required this.vendor,
    required this.isCreate,
  });

  @override
  State<VendorDetail> createState() => _VendorDetailState();
}

class _VendorDetailState extends State<VendorDetail> {
  VendorProvider vendorProvider = VendorProvider();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String vendorName = widget.vendor.name;
    String vendorAddress = widget.vendor.address;
    String vendorPhone = widget.vendor.phone;
    String vendorFax = widget.vendor.fax;
    String vendorContactPerson = widget.vendor.contactPerson;
    String vendorContactPersonPhone = widget.vendor.contactPersonPhone;
    String vendorContactPersonEmail = widget.vendor.contactPersonEmail;
    String vendorStatus = widget.vendor.status;
    String? vendorNote = widget.vendor.note;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendor.name),
      ),
      body: GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 10,
        ),
        children: [
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商名稱'),
                TextFormField(
                  initialValue: widget.vendor.name,
                  onChanged: (value) {
                    vendorName = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商地址'),
                TextFormField(
                  initialValue: widget.vendor.address,
                  onChanged: (value) {
                    vendorAddress = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商電話'),
                TextFormField(
                  initialValue: widget.vendor.phone,
                  onChanged: (value) {
                    vendorPhone = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商傳真'),
                TextFormField(
                  initialValue: widget.vendor.fax,
                  onChanged: (value) {
                    vendorFax = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商聯絡人'),
                TextFormField(
                  initialValue: widget.vendor.contactPerson,
                  onChanged: (value) {
                    vendorContactPerson = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商聯絡人電話'),
                TextFormField(
                  initialValue: widget.vendor.contactPersonPhone,
                  onChanged: (value) {
                    vendorContactPersonPhone = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商聯絡人信箱'),
                TextFormField(
                  initialValue: widget.vendor.contactPersonEmail,
                  onChanged: (value) {
                    vendorContactPersonEmail = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('廠商狀態'),
                TextFormField(
                  initialValue: widget.vendor.status,
                  onChanged: (value) {
                    vendorStatus = value;
                  },
                ),
              ]),
            ),
          ),
          Card(
            child: SizedBox(
              width: 200,
              child: Column(children: [
                const Text('備註'),
                TextFormField(
                  initialValue: widget.vendor.note,
                  onChanged: (value) {
                    vendorNote = value;
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (widget.isCreate) {
            await vendorProvider.insert(Vendor(
              name: vendorName,
              address: vendorAddress,
              phone: vendorPhone,
              fax: vendorFax,
              contactPerson: vendorContactPerson,
              contactPersonPhone: vendorContactPersonPhone,
              contactPersonEmail: vendorContactPersonEmail,
              status: vendorStatus,
              note: vendorNote,
            ));
          } else {
            await vendorProvider.update(
                widget.vendor.id!,
                Vendor(
                  id: widget.vendor.id,
                  name: vendorName,
                  address: vendorAddress,
                  phone: vendorPhone,
                  fax: vendorFax,
                  contactPerson: vendorContactPerson,
                  contactPersonPhone: vendorContactPersonPhone,
                  contactPersonEmail: vendorContactPersonEmail,
                  status: vendorStatus,
                  note: vendorNote,
                ));
          }
          if (!context.mounted) return;
          Navigator.pop(context, true);
        },
        child: widget.isCreate ? const Icon(Icons.save) : const Icon(Icons.edit),
      ),
    );
  }
}

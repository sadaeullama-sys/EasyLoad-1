import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const red = Color(0xffb51f2b);
const providers = ['Jazz', 'Zong', 'Telenor', 'Ufone', 'Udhaar App', 'One Load', 'Cash'];
const shopModules = ['Items / Stock', 'Purchase', 'Sales', 'Customers', 'Payments', 'Expenses', 'JazzCash', 'EasyPaisa', 'Reports'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShopDb.instance.init();
  runApp(const EasyLoadApp());
}

class ShopDb {
  ShopDb._();
  static final instance = ShopDb._();
  Database? db;

  Future<void> init() async {
    final base = await getDatabasesPath();
    db = await openDatabase(p.join(base, 'easyload_shop_manager.db'), version: 2,
      onCreate: (d, v) async {
        await d.execute('''CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT,module TEXT NOT NULL,title TEXT NOT NULL,amount REAL NOT NULL DEFAULT 0,paid REAL NOT NULL DEFAULT 0,note TEXT,created TEXT NOT NULL)''');
        await d.execute('''CREATE TABLE easyload_daily(id INTEGER PRIMARY KEY AUTOINCREMENT,ledger_date TEXT NOT NULL,company TEXT NOT NULL,opening_balance REAL NOT NULL DEFAULT 0,two_day_load REAL NOT NULL DEFAULT 0,sale REAL NOT NULL DEFAULT 0,rso_total_remaining REAL NOT NULL DEFAULT 0,today_transfer REAL NOT NULL DEFAULT 0,rso_katta REAL NOT NULL DEFAULT 0,note TEXT DEFAULT '',UNIQUE(ledger_date,company))''');
        await d.execute('''CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,category TEXT DEFAULT '',qty REAL NOT NULL DEFAULT 0,buy REAL NOT NULL DEFAULT 0,sell REAL NOT NULL DEFAULT 0,barcode TEXT DEFAULT '',qr_code TEXT DEFAULT '',imei TEXT DEFAULT '',created TEXT NOT NULL)''');
      },
      onUpgrade: (d, old, v) async {
        if (old < 2) {
          await d.execute('''CREATE TABLE IF NOT EXISTS items(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,category TEXT DEFAULT '',qty REAL NOT NULL DEFAULT 0,buy REAL NOT NULL DEFAULT 0,sell REAL NOT NULL DEFAULT 0,barcode TEXT DEFAULT '',qr_code TEXT DEFAULT '',imei TEXT DEFAULT '',created TEXT NOT NULL)''');
          await d.execute('CREATE INDEX IF NOT EXISTS idx_items_barcode ON items(barcode)');
        }
      },
    );
  }

  Future<List<Map<String, Object?>>> records(String module) => db!.query('records', where: 'module=?', whereArgs: [module], orderBy: 'id DESC');
  Future<void> addRecord(String module, String title, double amount, double paid, String note) async => db!.insert('records', {'module':module,'title':title,'amount':amount,'paid':paid,'note':note,'created':DateTime.now().toIso8601String()});
  Future<List<Map<String, Object?>>> ledger({String? date}) => db!.query('easyload_daily', where: date == null ? null : 'ledger_date=?', whereArgs: date == null ? null : [date], orderBy: 'ledger_date DESC, company ASC');
  Future<void> addLedger(String date, String company, double opening, double load, double sale, double rso, double transfer, double katta, String note) async {
    await db!.insert('easyload_daily', {'ledger_date':date,'company':company,'opening_balance':opening,'two_day_load':load,'sale':sale,'rso_total_remaining':rso,'today_transfer':transfer,'rso_katta':katta,'note':note}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<double> total(String module, String col) async {
    final r = await db!.rawQuery('SELECT COALESCE(SUM($col),0) n FROM records WHERE module=?', [module]);
    return (r.first['n'] as num).toDouble();
  }
  Future<List<Map<String,Object?>>> items() => db!.query('items', orderBy:'name COLLATE NOCASE');
  Future<Map<String,Object?>?> findItem(String code) async {
    final rows = await db!.query('items', where:'barcode=? OR qr_code=? OR imei=? OR name=? COLLATE NOCASE', whereArgs:[code,code,code,code], limit:1);
    return rows.isEmpty ? null : rows.first;
  }
  Future<void> saveItem(String name, String category, double qty, double buy, double sell, String code) async {
    await db!.insert('items', {'name':name,'category':category,'qty':qty,'buy':buy,'sell':sell,'barcode':code,'created':DateTime.now().toIso8601String()});
  }
}

class EasyLoadApp extends StatelessWidget {
  const EasyLoadApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(title:'EasyLoad Shop Manager', debugShowCheckedModeBanner:false,
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:red),useMaterial3:true,scaffoldBackgroundColor:const Color(0xfff5f6f8)), home:const HomePage());
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  int tab=0;
  void go(int index) => setState(()=>tab=index);
  @override Widget build(BuildContext context) {
    final destinations = <Widget>[
      const NavigationDrawerDestination(icon:Icon(Icons.dashboard_outlined),label:Text('Dashboard')),
      const NavigationDrawerDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:Text('EasyLoad Hisab')),
      const NavigationDrawerDestination(icon:Icon(Icons.qr_code_scanner),label:Text('Barcode / QR Scanner')),
      ...shopModules.map((m)=>NavigationDrawerDestination(icon:const Icon(Icons.folder_outlined),label:Text(m))),
    ];
    return Scaffold(appBar:AppBar(title:const Text('EasyLoad Shop Manager'),backgroundColor:red,foregroundColor:Colors.white, actions:[IconButton(tooltip:'Scan Barcode / QR',icon:const Icon(Icons.qr_code_scanner),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScannerPage())))]),
      drawer:NavigationDrawer(selectedIndex:tab,onDestinationSelected:(i){go(i);Navigator.pop(context);},children:[const Padding(padding:EdgeInsets.fromLTRB(24,20,16,12),child:Text('EASYLOAD SHOP MANAGER',style:TextStyle(fontWeight:FontWeight.bold))),...destinations]),
      body: tab==0 ? DashboardPage(onNavigate:go) : tab==1 ? const EasyLoadLedgerPage() : tab==2 ? const ScannerPage() : ModulePage(module:shopModules[tab-3]),
      bottomNavigationBar:NavigationBar(selectedIndex:tab==0?0:tab==1?1:2,onDestinationSelected:(i){if(i==2){showModalBottomSheet(context:context,builder:(ctx)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(Icons.inventory),title:const Text('Items / Stock'),onTap:(){Navigator.pop(ctx);go(3);}),ListTile(leading:const Icon(Icons.qr_code_scanner),title:const Text('Barcode Scanner'),onTap:(){Navigator.pop(ctx);go(2);}),ListTile(leading:const Icon(Icons.shopping_cart),title:const Text('Purchase'),onTap:(){Navigator.pop(ctx);go(4);})])));}else{go(i);}},destinations:const [NavigationDestination(icon:Icon(Icons.dashboard),label:'Home'),NavigationDestination(icon:Icon(Icons.receipt_long),label:'EasyLoad'),NavigationDestination(icon:Icon(Icons.menu),label:'More')]),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key,required this.onNavigate});
  String rs(num n)=>'Rs ${n.toStringAsFixed(0)}';
  @override Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future:Future.wait([ShopDb.instance.total('Sales','amount'),ShopDb.instance.total('Sales','paid'),ShopDb.instance.total('Purchase','amount'),ShopDb.instance.total('Expenses','amount'),ShopDb.instance.ledger(date:DateFormat('yyyy-MM-dd').format(DateTime.now())),ShopDb.instance.ledger()]),
    builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final sales=s.data![0] as double, received=s.data![1] as double, purchases=s.data![2] as double, expenses=s.data![3] as double;
      final today=s.data![4] as List<Map<String,Object?>>, recent=s.data![5] as List<Map<String,Object?>>;
      double sum(String key)=>today.fold(0.0,(v,r)=>v+(r[key] as num).toDouble());
      final totalBalance=sum('opening_balance')+sum('two_day_load');
      final remaining=totalBalance-sum('sale');
      final rsoLedger=sum('rso_total_remaining')-sum('today_transfer')-sum('rso_katta');
      return RefreshIndicator(onRefresh:()async{(context as Element).markNeedsBuild();},child:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Dashboard',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const Text('Shop overview and daily mobile-load accounts'),const SizedBox(height:14),
        GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.55,crossAxisSpacing:10,mainAxisSpacing:10,children:[_stat('Total Sales',rs(sales),Icons.point_of_sale),_stat('Received',rs(received),Icons.payments),_stat('Purchases',rs(purchases),Icons.shopping_cart),_stat('Expenses',rs(expenses),Icons.money_off)]),
        const SizedBox(height:16),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('EasyLoad Hisab — Today',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextButton(onPressed:()=>onNavigate(1),child:const Text('Open ledger'))]),
        GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.55,crossAxisSpacing:10,mainAxisSpacing:10,children:[_stat('Total Balance',rs(totalBalance),Icons.account_balance_wallet),_stat('Remaining',rs(remaining),Icons.wallet),_stat('RSO Remaining Ledger',rs(rsoLedger),Icons.swap_horiz),_stat('Today Transfer',rs(sum('today_transfer')),Icons.send)]),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Provider-wise EasyLoad Hisab',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),const SizedBox(height:8),...providers.map((name){final row=today.where((r)=>r['company']==name).toList();final r=row.isEmpty?null:row.first;final bal=r==null?0.0:(r['opening_balance'] as num).toDouble()+(r['two_day_load'] as num).toDouble()-(r['sale'] as num).toDouble();return ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:red.withOpacity(.10),child:Text(name[0],style:const TextStyle(color:red,fontWeight:FontWeight.bold))),title:Text(name),trailing:Text(rs(bal),style:const TextStyle(fontWeight:FontWeight.bold)));})]))),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Recent EasyLoad entries',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextButton(onPressed:()=>onNavigate(1),child:const Text('View all'))]),
        if(recent.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('No EasyLoad entries yet. Open EasyLoad Hisab to add today’s balances.'))),
        ...recent.take(5).map((r)=>Card(child:ListTile(leading:const Icon(Icons.receipt_long,color:red),title:Text('${r['company']} • ${r['ledger_date']}'),subtitle:Text('Sale: ${rs(r['sale'] as num)} | RSO Katta: ${rs(r['rso_katta'] as num)}'),trailing:Text(rs((r['opening_balance'] as num)+(r['two_day_load'] as num)-(r['sale'] as num)),style:const TextStyle(fontWeight:FontWeight.bold))))),
        const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.qr_code_scanner,color:red,size:30),title:const Text('Barcode / QR Scanner',style:TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('Scan product barcode with mobile camera or enter code manually'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScannerPage())))),
        const SizedBox(height:16),const Text('Developer: Muhammad Ilyas',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)),
      ]));
    });
  Widget _stat(String title,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon,color:red),Text(title),FittedBox(child:Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)))])));
}

class ScannerPage extends StatefulWidget { const ScannerPage({super.key}); @override State<ScannerPage> createState()=>_ScannerPageState(); }
class _ScannerPageState extends State<ScannerPage> {
  final code=TextEditingController(); String status='Point the camera at a product barcode or QR code.'; Map<String,Object?>? found; bool handled=false;
  Future<void> lookup(String value) async {final v=value.trim();if(v.isEmpty)return;final item=await ShopDb.instance.findItem(v);if(!mounted)return;setState(() { code.text=v; found=item; status=item==null?'Code scanned: $v — product not found. Add it in Items / Stock.':'Product found: ${item['name']}'; });}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Barcode / QR Scanner')),body:ListView(padding:const EdgeInsets.all(16),children:[
    ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(height:300,child:MobileScanner(onDetect:(capture){if(handled)return;if(capture.barcodes.isNotEmpty){final value=capture.barcodes.first.rawValue;if(value!=null){handled=true;lookup(value);}}}))),
    const SizedBox(height:14),Text(status,style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:12),
    TextField(controller:code,decoration:const InputDecoration(labelText:'Barcode / QR / IMEI',border:OutlineInputBorder(),prefixIcon:Icon(Icons.qr_code)),onSubmitted:lookup),const SizedBox(height:8),
    FilledButton.icon(onPressed:()=>lookup(code.text),icon:const Icon(Icons.search),label:const Text('Find Product')),
    if(found!=null)Card(child:ListTile(leading:const Icon(Icons.inventory_2,color:red),title:Text('${found!['name']}'),subtitle:Text('Qty: ${found!['qty']} • Buy: Rs ${found!['buy']} • Sell: Rs ${found!['sell']}'))),
    if(found==null && code.text.isNotEmpty)FilledButton.tonal(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ModulePage(module:'Items / Stock'))),child:const Text('Open Items / Stock')),
    const Text('USB barcode scanners that type the code can also be used in the code field.',style:TextStyle(color:Colors.black54)),
  ]));
}

class ModulePage extends StatefulWidget { final String module; const ModulePage({super.key,required this.module}); @override State<ModulePage> createState()=>_ModulePageState(); }
class _ModulePageState extends State<ModulePage>{
  final title=TextEditingController(),amount=TextEditingController(text:'0'),paid=TextEditingController(text:'0'),note=TextEditingController(),category=TextEditingController(),qty=TextEditingController(text:'1'),buy=TextEditingController(text:'0'),sell=TextEditingController(text:'0'),barcode=TextEditingController();
  Future<void> add()async{
    if(widget.module=='Items / Stock'){
      title.clear();category.clear();qty.text='1';buy.text='0';sell.text='0';barcode.clear();
      await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Add Stock Item'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[_field(title,'Product name'),_field(category,'Category'),_field(qty,'Quantity',number:true),_field(buy,'Buy price Rs.',number:true),_field(sell,'Sell price Rs.',number:true),Row(children:[Expanded(child:_field(barcode,'Barcode / QR / IMEI')),IconButton(tooltip:'Scan code',icon:const Icon(Icons.qr_code_scanner),onPressed:()async{final v=await Navigator.push<String>(ctx,MaterialPageRoute(builder:(_)=>const ScanCodeOnlyPage()));if(v!=null)barcode.text=v;})])])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{if(title.text.trim().isEmpty)return;await ShopDb.instance.saveItem(title.text,category.text,double.tryParse(qty.text)??0,double.tryParse(buy.text)??0,double.tryParse(sell.text)??0,barcode.text);if(ctx.mounted)Navigator.pop(ctx);setState((){});},child:const Text('Save'))]));
    }else{
      title.clear();amount.text='0';paid.text='0';note.clear();
      await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('New ${widget.module} Record'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[_field(title,'Name / Details'),_field(amount,'Amount (PKR)',number:true),_field(paid,'Paid / Received (PKR)',number:true),_field(note,'Note')])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{if(title.text.trim().isEmpty)return;await ShopDb.instance.addRecord(widget.module,title.text,double.tryParse(amount.text)??0,double.tryParse(paid.text)??0,note.text);if(ctx.mounted)Navigator.pop(ctx);setState((){});},child:const Text('Save'))]));
    }
    if(mounted)setState((){});
  }
  Widget _field(TextEditingController c,String label,{bool number=false})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  @override Widget build(BuildContext context){
    if(widget.module=='Items / Stock')return Scaffold(appBar:AppBar(title:Text(widget.module),actions:[IconButton(icon:const Icon(Icons.qr_code_scanner),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScannerPage())))]),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('Add Item')),body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.items(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const Center(child:Text('No stock items yet. Tap Add Item.'));return ListView(children:s.data!.map((r)=>Card(child:ListTile(title:Text('${r['name']}'),subtitle:Text('Code: ${r['barcode']} • Qty: ${r['qty']}\nBuy Rs ${r['buy']} • Sell Rs ${r['sell']}'),isThreeLine:true,leading:const Icon(Icons.inventory_2,color:red)))).toList());}));
    return Scaffold(appBar:AppBar(title:Text(widget.module),actions:[if(widget.module=='Purchase')IconButton(tooltip:'Scan barcode',icon:const Icon(Icons.qr_code_scanner),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScannerPage())))]),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('Add Record')),body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.records(widget.module),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const Center(child:Text('No records yet. Tap Add Record to begin.'));return ListView(children:s.data!.map((r)=>Card(child:ListTile(title:Text('${r['title']}'),subtitle:Text('${r['created']}\n${r['note']??''}'),isThreeLine:true,trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text('Rs ${r['amount']}'),Text('Paid ${r['paid']}')])))).toList());}));
  }
}

class ScanCodeOnlyPage extends StatefulWidget { const ScanCodeOnlyPage({super.key}); @override State<ScanCodeOnlyPage> createState()=>_ScanCodeOnlyPageState(); }
class _ScanCodeOnlyPageState extends State<ScanCodeOnlyPage>{bool done=false;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Scan product code')),body:MobileScanner(onDetect:(capture){if(done)return;final value=capture.barcodes.isNotEmpty?capture.barcodes.first.rawValue:null;if(value!=null){done=true;Navigator.pop(context,value);}}));}

class EasyLoadLedgerPage extends StatefulWidget { const EasyLoadLedgerPage({super.key}); @override State<EasyLoadLedgerPage> createState()=>_EasyLoadLedgerPageState(); }
class _EasyLoadLedgerPageState extends State<EasyLoadLedgerPage>{
  final date=DateFormat('yyyy-MM-dd').format(DateTime.now());final ctrls=List.generate(6,(_)=>TextEditingController(text:'0'));final note=TextEditingController();String company='Jazz';
  double n(int i)=>double.tryParse(ctrls[i].text.trim())??0;
  Future<void> add()async{for(final c in ctrls){c.text=c.text.trim().isEmpty?'0':c.text;}await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(title:const Text('New EasyLoad Hisab'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(value:company,items:providers.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>refresh(()=>company=v??'Jazz'),decoration:const InputDecoration(labelText:'Company / Provider')),...['Opening Balance','2 Day Load','Sale','RSO Total Remaining','Today Transfer','RSO Katta'].asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:ctrls[e.key],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:e.value,border:const OutlineInputBorder())))),TextField(controller:note,decoration:const InputDecoration(labelText:'Note'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{await ShopDb.instance.addLedger(date,company,n(0),n(1),n(2),n(3),n(4),n(5),note.text);if(ctx.mounted)Navigator.pop(ctx);if(mounted)setState((){});},child:const Text('Save'))])));}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('EasyLoad Hisab')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('New Record')),body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.ledger(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(12),children:[const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Formulas: Total Balance = Opening Balance + 2 Day Load | Remaining = Total Balance − Sale | Remaining Ledger = RSO Total Remaining − Today Transfer − RSO Katta'))),if(s.data!.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Text('No EasyLoad records yet. Tap New Record.')),...s.data!.map((r){final total=(r['opening_balance'] as num).toDouble()+(r['two_day_load'] as num).toDouble();final remaining=total-(r['sale'] as num).toDouble();final ledger=(r['rso_total_remaining'] as num).toDouble()-(r['today_transfer'] as num).toDouble()-(r['rso_katta'] as num).toDouble();return Card(child:ExpansionTile(title:Text('${r['company']} • ${r['ledger_date']}'),subtitle:Text('Total Balance: Rs ${total.toStringAsFixed(2)} • Remaining: Rs ${remaining.toStringAsFixed(2)}'),childrenPadding:const EdgeInsets.all(12),children:[_line('Opening Balance',r['opening_balance']),_line('2 Day Load',r['two_day_load']),_line('Total Balance',total),_line('Sale',r['sale']),_line('Remaining',remaining),_line('RSO Total Remaining',r['rso_total_remaining']),_line('Today Transfer',r['today_transfer']),_line('RSO Katta',r['rso_katta']),_line('Remaining Ledger',ledger),Text('${r['note']??''}') ]));})]);}));
  Widget _line(String label,Object? value)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label),Text('Rs ${(value as num).toStringAsFixed(2)}',style:const TextStyle(fontWeight:FontWeight.w600))]));
}

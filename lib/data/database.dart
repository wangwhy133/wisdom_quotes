import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

enum QuoteCategory {
  classicLiterature,
  poetry,
  investment,
}

class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get author => text()();
  TextColumn get source => text().nullable()();
  IntColumn get category => intEnum<QuoteCategory>()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Quotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(quotes, quotes.notes);
        }
        if (from < 3) {
          await m.addColumn(quotes, quotes.isRead);
        }
      },
    );
  }

  Future<void> _seedData() async {
    // ============ 经典名著 (50条) ============
    final classics = <QuotesCompanion>[
      QuotesCompanion.insert(content: '所有杀不死我的，都使我更强大。', author: '弗里德里希·尼采', source: const Value('《偶像的黄昏》'), category: QuoteCategory.classicLiterature, tags: const Value('哲学,力量,成长')),
      QuotesCompanion.insert(content: '幸福的家庭都是相似的，不幸的家庭各有各的不幸。', author: '列夫·托尔斯泰', source: const Value('《安娜·卡列尼娜》'), category: QuoteCategory.classicLiterature, tags: const Value('家庭,幸福')),
      QuotesCompanion.insert(content: '这是最好的时代，这是最坏的时代。', author: '查尔斯·狄更斯', source: const Value('《双城记》'), category: QuoteCategory.classicLiterature, tags: const Value('时代,矛盾')),
      QuotesCompanion.insert(content: '生存还是毁灭，这是一个问题。', author: '威廉·莎士比亚', source: const Value('《哈姆雷特》'), category: QuoteCategory.classicLiterature, tags: const Value('存在,选择')),
      QuotesCompanion.insert(content: '人最宝贵的是生命，生命对于每个人只有一次。', author: '奥斯特洛夫斯基', source: const Value('《钢铁是怎样炼成的》'), category: QuoteCategory.classicLiterature, tags: const Value('生命,价值')),
      QuotesCompanion.insert(content: '围在城里的人想逃出来，城外的人想冲进去。', author: '钱钟书', source: const Value('《围城》'), category: QuoteCategory.classicLiterature, tags: const Value('人生,矛盾')),
      QuotesCompanion.insert(content: '世界以痛吻我，要我报之以歌。', author: '泰戈尔', source: const Value('《飞鸟集》'), category: QuoteCategory.classicLiterature, tags: const Value('豁达,态度')),
      QuotesCompanion.insert(content: '满地黄花堆积，憔悴损，如今有谁堪摘？', author: '李清照', source: const Value('《声声慢》'), category: QuoteCategory.classicLiterature, tags: const Value('哀愁,秋天')),
      QuotesCompanion.insert(content: '一个人并不是生来要给打败的，你尽可以把他消灭掉，可就是打不败他。', author: '海明威', source: const Value('《老人与海》'), category: QuoteCategory.classicLiterature, tags: const Value('坚韧,勇气')),
      QuotesCompanion.insert(content: '当你凝视深渊时，深渊也在凝视你。', author: '弗里德里希·尼采', source: const Value('《善恶的彼岸》'), category: QuoteCategory.classicLiterature, tags: const Value('哲学,警示')),
      QuotesCompanion.insert(content: '我年华虚度，空有一身疲倦。', author: '海子', source: const Value('《以梦为马》'), category: QuoteCategory.classicLiterature, tags: const Value('青春,遗憾')),
      QuotesCompanion.insert(content: '我们听过无数的道理，却仍旧过不好这一生。', author: '韩寒', source: const Value('《后会无期》'), category: QuoteCategory.classicLiterature, tags: const Value('人生,哲理')),
      QuotesCompanion.insert(content: '人生天地之间，若白驹过隙，忽然而已。', author: '庄周', source: const Value('《庄子》'), category: QuoteCategory.classicLiterature, tags: const Value('时间,人生')),
      QuotesCompanion.insert(content: '我不同意你的观点，但我誓死捍卫你说话的权利。', author: '伏尔泰', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('自由,言论')),
      QuotesCompanion.insert(content: '存在即合理。', author: '格奥尔格·黑格尔', source: const Value('《法哲学原理》'), category: QuoteCategory.classicLiterature, tags: const Value('哲学,存在')),
      QuotesCompanion.insert(content: '人的一切痛苦，本质上都是对自己无能的愤怒。', author: '王小波', source: const Value('《沉默的大多数》'), category: QuoteCategory.classicLiterature, tags: const Value('痛苦,自省')),
      QuotesCompanion.insert(content: '要么孤独，要么庸俗。', author: '叔本华', source: const Value('《人生的智慧》'), category: QuoteCategory.classicLiterature, tags: const Value('孤独,哲学')),
      QuotesCompanion.insert(content: '生命中真正重要的不是你遭遇了什么，而是你记住了哪些事，又是如何铭记的。', author: '加夫列尔·马尔克斯', source: const Value('《百年孤独》'), category: QuoteCategory.classicLiterature, tags: const Value('记忆,人生')),
      QuotesCompanion.insert(content: '只有流过血的手指，才能弹出世间的绝唱。', author: '泰戈尔', source: const Value('《飞鸟集》'), category: QuoteCategory.classicLiterature, tags: const Value('磨难,成就')),
      QuotesCompanion.insert(content: '当你老了，回顾一生，就会发觉：什么时候出国读书、什么时候决定做第一份职业、何时选定了对象而恋爱、什么时候结婚，其实都是命运的巨变。', author: '陶杰', source: const Value('《杀鹌鹑的少女》'), category: QuoteCategory.classicLiterature, tags: const Value('选择,命运')),
      QuotesCompanion.insert(content: '从前的日色变得慢，车，马，邮件都慢，一生只够爱一个人。', author: '木心', source: const Value('《从前慢》'), category: QuoteCategory.classicLiterature, tags: const Value('慢生活,爱情')),
      QuotesCompanion.insert(content: '我行过许多地方的桥，看过许多次数的云，喝过许多种类的酒，却只爱过一个正当最好年龄的人。', author: '沈从文', source: const Value('《湘行散记》'), category: QuoteCategory.classicLiterature, tags: const Value('爱情,经历')),
      QuotesCompanion.insert(content: '愿中国青年都摆脱冷气，只是向上走，不必听自暴自弃者流的话。', author: '鲁迅', source: const Value('《热风》'), category: QuoteCategory.classicLiterature, tags: const Value('青年,奋斗')),
      QuotesCompanion.insert(content: '人类的悲欢并不相通，我只觉得他们吵闹。', author: '鲁迅', source: const Value('《而已集》'), category: QuoteCategory.classicLiterature, tags: const Value('孤独,共鸣')),
      QuotesCompanion.insert(content: '向来缘浅，奈何情深。', author: '顾漫', source: const Value('《何以笙箫默》'), category: QuoteCategory.classicLiterature, tags: const Value('爱情,无奈')),
      QuotesCompanion.insert(content: '山不在高，有仙则名；水不在深，有龙则灵。', author: '刘禹锡', source: const Value('《陋室铭》'), category: QuoteCategory.classicLiterature, tags: const Value('境界,心态')),
      QuotesCompanion.insert(content: '不以物喜，不以己悲。', author: '范仲淹', source: const Value('《岳阳楼记》'), category: QuoteCategory.classicLiterature, tags: const Value('豁达,心态')),
      QuotesCompanion.insert(content: '古之成大事者，不惟有超世之才，亦必有坚忍不拔之志。', author: '苏轼', source: const Value('《晁错论》'), category: QuoteCategory.classicLiterature, tags: const Value('志向,毅力')),
      QuotesCompanion.insert(content: '天行健，君子以自强不息；地势坤，君子以厚德载物。', author: '姬昌', source: const Value('《周易》'), category: QuoteCategory.classicLiterature, tags: const Value('自强,品德')),
      QuotesCompanion.insert(content: '业精于勤，荒于嬉；行成于思，毁于随。', author: '韩愈', source: const Value('《进学解》'), category: QuoteCategory.classicLiterature, tags: const Value('勤奋,思考')),
      QuotesCompanion.insert(content: '生活不可能像你想象的那么好，但也不会像你想象的那么糟。', author: '莫泊桑', source: const Value('《一生》'), category: QuoteCategory.classicLiterature, tags: const Value('生活,坚韧')),
      QuotesCompanion.insert(content: '人的本能是追逐从他身边飞走的东西，却逃避追逐他的东西。', author: '伏尔泰', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('人性,欲望')),
      QuotesCompanion.insert(content: '凡是不能杀死我的，都会令我更强。', author: '尼采', source: const Value('《偶像的黄昏》'), category: QuoteCategory.classicLiterature, tags: const Value('磨难,成长')),
      QuotesCompanion.insert(content: '黑夜无论怎样悠长，白昼总会到来。', author: '莎士比亚', source: const Value('《麦克白》'), category: QuoteCategory.classicLiterature, tags: const Value('希望,黑暗')),
      QuotesCompanion.insert(content: '我荒废了时间，时间便把我荒废了。', author: '莎士比亚', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('时间,珍惜')),
      QuotesCompanion.insert(content: '你那么憎恨那些人，和他们斗了那么久，最终却变得和他们一样。', author: '尼采', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('斗争,反思')),
      QuotesCompanion.insert(content: 'If you want to kill a crow, just throw a stone at it. But if you want to kill a general, you need a better weapon.', author: 'Sun Tzu', source: const Value('The Art of War'), category: QuoteCategory.classicLiterature, tags: const Value('strategy,war')),
      QuotesCompanion.insert(content: '没有人是一座孤岛，在大海里独踞。', author: '约翰·多恩', source: const Value('《没有人是一座孤岛》'), category: QuoteCategory.classicLiterature, tags: const Value('联系,人类命运')),
      QuotesCompanion.insert(content: '不要努力成为一个成功者，要努力成为一个有价值的人。', author: '阿尔伯特·爱因斯坦', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('价值,成功')),
      QuotesCompanion.insert(content: '想象力比知识更重要。', author: '阿尔伯特·爱因斯坦', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('想象,知识')),
      QuotesCompanion.insert(content: '你要批评指点四周风景，首先要爬上屋顶。', author: '歌德', source: const Value('《歌德谈话录》'), category: QuoteCategory.classicLiterature, tags: const Value('视野,高度')),
      QuotesCompanion.insert(content: '愤怒是愚蠢的第一种表现。', author: '俾斯麦', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('情绪,智慧')),
      QuotesCompanion.insert(content: '失败也是我所需要的，它和成功一样对我有价值。', author: '爱迪生', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('失败,价值')),
      QuotesCompanion.insert(content: '最困难之时，就是离成功不远之日。', author: '拿破仑·波拿巴', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('坚持,成功')),
      QuotesCompanion.insert(content: '要散布阳光到别人心里，先得自己心里有阳光。', author: '罗曼·罗兰', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('阳光,心态')),
      QuotesCompanion.insert(content: '先相信你自己，然后别人才会相信你。', author: '屠格涅夫', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('自信,信任')),
      QuotesCompanion.insert(content: '不会思考的人是傻瓜，不肯思考的人是懒汉。', author: '赫尔巴特', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('思考,智慧')),
      QuotesCompanion.insert(content: '我没有什么特别的才能，我只是极度好奇。', author: '爱因斯坦', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('好奇,才能')),
      QuotesCompanion.insert(content: '兴趣是最好的老师。', author: '爱因斯坦', source: const Value(''), category: QuoteCategory.classicLiterature, tags: const Value('兴趣,学习')),
    ];

    // ============ 诗词 (50条) ============
    final poems = <QuotesCompanion>[
      QuotesCompanion.insert(content: '人生若只如初见，何事秋风悲画扇。', author: '纳兰性德', source: const Value('《木兰花·拟古决绝词》'), category: QuoteCategory.poetry, tags: const Value('爱情,感慨')),
      QuotesCompanion.insert(content: '曾经沧海难为水，除却巫山不是云。', author: '元稹', source: const Value('《离思五首》'), category: QuoteCategory.poetry, tags: const Value('爱情,忠贞')),
      QuotesCompanion.insert(content: '大江东去，浪淘尽，千古风流人物。', author: '苏轼', source: const Value('《念奴娇·赤壁怀古》'), category: QuoteCategory.poetry, tags: const Value('历史,豪迈')),
      QuotesCompanion.insert(content: '但愿人长久，千里共婵娟。', author: '苏轼', source: const Value('《水调歌头》'), category: QuoteCategory.poetry, tags: const Value('祝愿,思念')),
      QuotesCompanion.insert(content: '人生如逆旅，我亦是行人。', author: '苏轼', source: const Value('《临江仙·送钱穆父》'), category: QuoteCategory.poetry, tags: const Value('人生,豁达')),
      QuotesCompanion.insert(content: '春风得意马蹄疾，一日看尽长安花。', author: '孟郊', source: const Value('《登科后》'), category: QuoteCategory.poetry, tags: const Value('得意,欢快')),
      QuotesCompanion.insert(content: '长风破浪会有时，直挂云帆济沧海。', author: '李白', source: const Value('《行路难》'), category: QuoteCategory.poetry, tags: const Value('励志,豪迈')),
      QuotesCompanion.insert(content: '采菊东篱下，悠然见南山。', author: '陶渊明', source: const Value('《饮酒·其五》'), category: QuoteCategory.poetry, tags: const Value('田园,闲适')),
      QuotesCompanion.insert(content: '海上生明月，天涯共此时。', author: '张九龄', source: const Value('《望月怀远》'), category: QuoteCategory.poetry, tags: const Value('明月,思念')),
      QuotesCompanion.insert(content: '两情若是久长时，又岂在朝朝暮暮。', author: '秦观', source: const Value('《鹊桥仙》'), category: QuoteCategory.poetry, tags: const Value('爱情,永恒')),
      QuotesCompanion.insert(content: '问世间，情为何物，直教生死相许。', author: '元好问', source: const Value('《摸鱼儿》'), category: QuoteCategory.poetry, tags: const Value('爱情,生死')),
      QuotesCompanion.insert(content: '众里寻他千百度，蓦然回首，那人却在，灯火阑珊处。', author: '辛弃疾', source: const Value('《青玉案·元夕》'), category: QuoteCategory.poetry, tags: const Value('寻找,缘分')),
      QuotesCompanion.insert(content: '莫听穿林打叶声，何妨吟啸且徐行。', author: '苏轼', source: const Value('《定风波》'), category: QuoteCategory.poetry, tags: const Value('豁达,从容')),
      QuotesCompanion.insert(content: '竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。', author: '苏轼', source: const Value('《定风波》'), category: QuoteCategory.poetry, tags: const Value('豁达,人生')),
      QuotesCompanion.insert(content: '回首向来萧瑟处，归去，也无风雨也无晴。', author: '苏轼', source: const Value('《定风波》'), category: QuoteCategory.poetry, tags: const Value('淡然,超脱')),
      QuotesCompanion.insert(content: '人有悲欢离合，月有阴晴圆缺，此事古难全。', author: '苏轼', source: const Value('《水调歌头》'), category: QuoteCategory.poetry, tags: const Value('豁达,人生')),
      QuotesCompanion.insert(content: '春宵一刻值千金，花有清香月有阴。', author: '苏轼', source: const Value('《春宵》'), category: QuoteCategory.poetry, tags: const Value('时光,美好')),
      QuotesCompanion.insert(content: '不识庐山真面目，只缘身在此山中。', author: '苏轼', source: const Value('《题西林壁》'), category: QuoteCategory.poetry, tags: const Value('哲理,旁观')),
      QuotesCompanion.insert(content: '日啖荔枝三百颗，不辞长作岭南人。', author: '苏轼', source: const Value('《惠州一绝》'), category: QuoteCategory.poetry, tags: const Value('乐观,随遇而安')),
      QuotesCompanion.insert(content: '人生到处知何似，应似飞鸿踏雪泥。', author: '苏轼', source: const Value('《和子由渑池怀旧》'), category: QuoteCategory.poetry, tags: const Value('人生,漂泊')),
      QuotesCompanion.insert(content: '十年生死两茫茫，不思量，自难忘。', author: '苏轼', source: const Value('《江城子》'), category: QuoteCategory.poetry, tags: const Value('思念,爱情')),
      QuotesCompanion.insert(content: '明月几时有，把酒问青天。', author: '苏轼', source: const Value('《水调歌头》'), category: QuoteCategory.poetry, tags: const Value('明月,豪放')),
      QuotesCompanion.insert(content: '我见青山多妩媚，料青山见我应如是。', author: '辛弃疾', source: const Value('《贺新郎》'), category: QuoteCategory.poetry, tags: const Value('自信,超然')),
      QuotesCompanion.insert(content: '醉里挑灯看剑，梦回吹角连营。', author: '辛弃疾', source: const Value('《破阵子》'), category: QuoteCategory.poetry, tags: const Value('壮志,豪迈')),
      QuotesCompanion.insert(content: '想当年，金戈铁马，气吞万里如虎。', author: '辛弃疾', source: const Value('《永遇乐·京口北固亭怀古》'), category: QuoteCategory.poetry, tags: const Value('豪迈,壮志')),
      QuotesCompanion.insert(content: '青山遮不住，毕竟东流去。', author: '辛弃疾', source: const Value('《菩萨蛮·书江西造口壁》'), category: QuoteCategory.poetry, tags: const Value('历史,哲理')),
      QuotesCompanion.insert(content: '了却君王天下事，赢得生前身后名。', author: '辛弃疾', source: const Value('《破阵子》'), category: QuoteCategory.poetry, tags: const Value('志向,忠君')),
      QuotesCompanion.insert(content: '今宵酒醒何处，杨柳岸，晓风残月。', author: '柳永', source: const Value('《雨霖铃》'), category: QuoteCategory.poetry, tags: const Value('离别,婉约')),
      QuotesCompanion.insert(content: '多情自古伤离别，更那堪，冷落清秋节。', author: '柳永', source: const Value('《雨霖铃》'), category: QuoteCategory.poetry, tags: const Value('离别,伤感')),
      QuotesCompanion.insert(content: '衣带渐宽终不悔，为伊消得人憔悴。', author: '柳永', source: const Value('《蝶恋花》'), category: QuoteCategory.poetry, tags: const Value('爱情,执着')),
      QuotesCompanion.insert(content: '此去经年，应是良辰好景虚设。便纵有千种风情，更与何人说。', author: '柳永', source: const Value('《雨霖铃》'), category: QuoteCategory.poetry, tags: const Value('孤独,感慨')),
      QuotesCompanion.insert(content: '寻寻觅觅，冷冷清清，凄凄惨惨戚戚。', author: '李清照', source: const Value('《声声慢》'), category: QuoteCategory.poetry, tags: const Value('孤独,哀愁')),
      QuotesCompanion.insert(content: '知否知否，应是绿肥红瘦。', author: '李清照', source: const Value('《如梦令》'), category: QuoteCategory.poetry, tags: const Value('自然,婉约')),
      QuotesCompanion.insert(content: '生当作人杰，死亦为鬼雄。', author: '李清照', source: const Value('《夏日绝句》'), category: QuoteCategory.poetry, tags: const Value('豪迈,气节')),
      QuotesCompanion.insert(content: '至今思项羽，不肯过江东。', author: '李清照', source: const Value('《夏日绝句》'), category: QuoteCategory.poetry, tags: const Value('气节,英雄')),
      QuotesCompanion.insert(content: '无言独上西楼，月如钩，寂寞梧桐深院锁清秋。', author: '李煜', source: const Value('《相见欢》'), category: QuoteCategory.poetry, tags: const Value('孤独,离愁')),
      QuotesCompanion.insert(content: '剪不断，理还乱，是离愁，别是一般滋味在心头。', author: '李煜', source: const Value('《相见欢》'), category: QuoteCategory.poetry, tags: const Value('离愁,苦涩')),
      QuotesCompanion.insert(content: '问君能有几多愁，恰似一江春水向东流。', author: '李煜', source: const Value('《虞美人》'), category: QuoteCategory.poetry, tags: const Value('亡国,哀愁')),
      QuotesCompanion.insert(content: '春花秋月何时了，往事知多少。', author: '李煜', source: const Value('《虞美人》'), category: QuoteCategory.poetry, tags: const Value('亡国,感慨')),
      QuotesCompanion.insert(content: '梦里不知身是客，一晌贪欢。', author: '李煜', source: const Value('《浪淘沙》'), category: QuoteCategory.poetry, tags: const Value('亡国,悲凉')),
      QuotesCompanion.insert(content: '独自莫凭栏，无限江山，别时容易见时难。', author: '李煜', source: const Value('《浪淘沙》'), category: QuoteCategory.poetry, tags: const Value('亡国,离愁')),
      QuotesCompanion.insert(content: '流水落花春去也，天上人间。', author: '李煜', source: const Value('《浪淘沙》'), category: QuoteCategory.poetry, tags: const Value('亡国,感慨')),
      QuotesCompanion.insert(content: '胭脂泪，相留醉，几时重，自是人生长恨水长东。', author: '李煜', source: const Value('《相见欢》'), category: QuoteCategory.poetry, tags: const Value('离愁,人生')),
      QuotesCompanion.insert(content: '蜡烛有心还惜别，替人垂泪到天明。', author: '杜牧', source: const Value('《赠别》'), category: QuoteCategory.poetry, tags: const Value('离别,情感')),
      QuotesCompanion.insert(content: '商女不知亡国恨，隔江犹唱后庭花。', author: '杜牧', source: const Value('《泊秦淮》'), category: QuoteCategory.poetry, tags: const Value('亡国,讽刺')),
      QuotesCompanion.insert(content: '东风不与周郎便，铜雀春深锁二乔。', author: '杜牧', source: const Value('《赤壁》'), category: QuoteCategory.poetry, tags: const Value('历史,机遇')),
      QuotesCompanion.insert(content: '天街小雨润如酥，草色遥看近却无。', author: '韩愈', source: const Value('《早春呈水部张十八员外》'), category: QuoteCategory.poetry, tags: const Value('早春,自然')),
      QuotesCompanion.insert(content: '最是一年春好处，绝胜烟柳满皇都。', author: '韩愈', source: const Value('《早春呈水部张十八员外》'), category: QuoteCategory.poetry, tags: const Value('早春,美好')),
      QuotesCompanion.insert(content: '晴空一鹤排云上，便引诗情到碧霄。', author: '刘禹锡', source: const Value('《秋词》'), category: QuoteCategory.poetry, tags: const Value('秋日,豪情')),
    ];

    // ============ 投资名言 (50条) ============
    final investments = <QuotesCompanion>[
      QuotesCompanion.insert(content: '别人贪婪时我恐惧，别人恐惧时我贪婪。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('逆向思维,风险')),
      QuotesCompanion.insert(content: '投资的第一原则是永远不要亏钱，第二原则是记住第一原则。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('风险,本金保护')),
      QuotesCompanion.insert(content: '如果你不愿意持有一只股票十年，那就不要考虑持有它十分钟。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('长期主义,价值投资')),
      QuotesCompanion.insert(content: '价格是你付出的，价值是你得到的。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('价值,价格')),
      QuotesCompanion.insert(content: '风险来自于不知道自己在做什么。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('风险,认知')),
      QuotesCompanion.insert(content: '预测市场短期走势是不可能的，预测市场长期走势是可行的。', author: '本杰明·格雷厄姆', source: const Value('《聪明的投资者》'), category: QuoteCategory.investment, tags: const Value('市场,预测')),
      QuotesCompanion.insert(content: '投资就是寻找价值被低估的证券。', author: '本杰明·格雷厄姆', source: const Value('《证券分析》'), category: QuoteCategory.investment, tags: const Value('价值投资,选股')),
      QuotesCompanion.insert(content: '要在别人贪婪时恐惧，在别人恐惧时贪婪。', author: '乔治·索罗斯', source: const Value('量子基金'), category: QuoteCategory.investment, tags: const Value('逆向思维')),
      QuotesCompanion.insert(content: '止损永远是对的，错了也对；死扛永远是错的，对了也错。', author: '华尔街名言', source: const Value(''), category: QuoteCategory.investment, tags: const Value('止损,风险管理')),
      QuotesCompanion.insert(content: '截断亏损，让利润奔跑。', author: '华尔街名言', source: const Value(''), category: QuoteCategory.investment, tags: const Value('交易,纪律')),
      QuotesCompanion.insert(content: '单一标的持仓不超过总仓位的10%，单一行业不超过30%。', author: '现代投资组合理论', source: const Value(''), category: QuoteCategory.investment, tags: const Value('分散投资,仓位管理')),
      QuotesCompanion.insert(content: '本金安全是投资的第一要务。', author: '塞思·克拉曼', source: const Value('《安全边际》'), category: QuoteCategory.investment, tags: const Value('本金保护,风险管理')),
      QuotesCompanion.insert(content: '投资回报取决于你支付的价格和你等待的时间。', author: '约翰·博格', source: const Value('先锋集团'), category: QuoteCategory.investment, tags: const Value('回报,时间')),
      QuotesCompanion.insert(content: '不要把鸡蛋放在一个篮子里。', author: '哈里·马克维茨', source: const Value('现代投资组合理论'), category: QuoteCategory.investment, tags: const Value('分散,风险')),
      QuotesCompanion.insert(content: '市场是非理性的，短期涨跌完全无法预测。', author: '约翰·梅纳德·凯恩斯', source: const Value(''), category: QuoteCategory.investment, tags: const Value('市场,非理性')),
      QuotesCompanion.insert(content: '当潮水退去的时候，才知道谁在裸泳。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('风险,警示')),
      QuotesCompanion.insert(content: '持有一只股票最好的方式是永远。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('长期持有')),
      QuotesCompanion.insert(content: '找到杰出的公司，然后长期持有。', author: '彼得·林奇', source: const Value('富达基金'), category: QuoteCategory.investment, tags: const Value('长期投资,选股')),
      QuotesCompanion.insert(content: '卖出赔钱的股票，让赚钱的股票继续奔跑。', author: '彼得·林奇', source: const Value('富达基金'), category: QuoteCategory.investment, tags: const Value('交易策略')),
      QuotesCompanion.insert(content: '知道自己不知道什么，比认为自己什么都知道重要得多。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('认知,智慧')),
      QuotesCompanion.insert(content: '好公司便宜买，才是真正的好买卖。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('价值投资')),
      QuotesCompanion.insert(content: '股价公道的伟大企业，比股价超低的普通企业更值得投资。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('价值投资,质量')),
      QuotesCompanion.insert(content: '模糊的正确远胜于精确的错误。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('决策,智慧')),
      QuotesCompanion.insert(content: '在别人恐惧时贪婪，在别人贪婪时恐惧。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('逆向思维,情绪')),
      QuotesCompanion.insert(content: '投资不需要高智商，但需要高情商。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('情商,投资')),
      QuotesCompanion.insert(content: '耐心是投资者最重要的品质。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('耐心,品质')),
      QuotesCompanion.insert(content: '能力圈的大小不重要，重要的是知道它的边界在哪里。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('能力圈,自知')),
      QuotesCompanion.insert(content: '如果你不想持有一只股票十年，那就不要考虑持有它十分钟。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('长期主义')),
      QuotesCompanion.insert(content: '时间是优秀企业的朋友，是平庸企业的敌人。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('时间,企业质量')),
      QuotesCompanion.insert(content: '少即是多。专注比分散能带来更好的回报。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('专注,集中')),
      QuotesCompanion.insert(content: '投资最危险的敌人是复利。', author: '未知', source: const Value(''), category: QuoteCategory.investment, tags: const Value('复利,警示')),
      QuotesCompanion.insert(content: '不要试图时机市场，不要试图波段操作。', author: '彼得·林奇', source: const Value('富达基金'), category: QuoteCategory.investment, tags: const Value('时机,波段')),
      QuotesCompanion.insert(content: '你有你的资产有现金，你的市场分析有现金，你的情绪也有现金。', author: '霍华德·马克斯', source: const Value('橡树资本'), category: QuoteCategory.investment, tags: const Value('现金,风险管理')),
      QuotesCompanion.insert(content: '世界上最糟糕的事情是，你持有的资产开始盈利但你却赎回了。', author: '霍华德·马克斯', source: const Value('橡树资本'), category: QuoteCategory.investment, tags: const Value('持有,耐心')),
      QuotesCompanion.insert(content: '优秀的投资者和糟糕的投资者的区别在于，他们能否在压力下保持冷静。', author: '霍华德·马克斯', source: const Value('橡树资本'), category: QuoteCategory.investment, tags: const Value('心理,情绪')),
      QuotesCompanion.insert(content: '风险意味着，可能发生的事情比将要发生的事情更多。', author: '纳西姆·塔勒布', source: const Value('《黑天鹅》'), category: QuoteCategory.investment, tags: const Value('风险,不确定性')),
      QuotesCompanion.insert(content: '不要相信那些在市场上赚钱的人说的话。', author: '纳西姆·塔勒布', source: const Value('《黑天鹅》'), category: QuoteCategory.investment, tags: const Value('警示,怀疑')),
      QuotesCompanion.insert(content: '你不是因为正确而赚钱，而是因为你正确地下了注。', author: '纳西姆·塔勒布', source: const Value('《黑天鹅》'), category: QuoteCategory.investment, tags: const Value('下注,风险回报')),
      QuotesCompanion.insert(content: '永远不要忘记风险，也不要忘记收益。', author: '威廉·夏普', source: const Value('资本资产定价模型'), category: QuoteCategory.investment, tags: const Value('风险,收益')),
      QuotesCompanion.insert(content: '多样化是对无知的保护。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('多样化,保护')),
      QuotesCompanion.insert(content: '如果我没有找到足够好的投资机会，我就什么都不做。', author: '沃伦·巴菲特', source: const Value('伯克希尔·哈撒韦'), category: QuoteCategory.investment, tags: const Value('耐心,机会')),
      QuotesCompanion.insert(content: '最大的风险是不投资的风险。', author: '麦尔·斯特劳斯', source: const Value(''), category: QuoteCategory.investment, tags: const Value('风险,机会成本')),
      QuotesCompanion.insert(content: '成功不在于你做什么，而在于你不做什么。', author: '托马斯·沃森', source: const Value('IBM'), category: QuoteCategory.investment, tags: const Value('纪律,耐心')),
      QuotesCompanion.insert(content: '你永远无法在底部买进，在顶部卖出。', author: '约翰·坦伯顿', source: const Value('坦伯顿基金'), category: QuoteCategory.investment, tags: const Value('时机,现实')),
      QuotesCompanion.insert(content: '危机就是机会，每一次危机都蕴藏着巨大的机遇。', author: '约翰·坦伯顿', source: const Value('坦伯顿基金'), category: QuoteCategory.investment, tags: const Value('危机,机遇')),
      QuotesCompanion.insert(content: '最简单的投资策略往往是最有效的。', author: '约翰·博格', source: const Value('先锋集团'), category: QuoteCategory.investment, tags: const Value('简单,有效')),
      QuotesCompanion.insert(content: '指数基金是最好的投资。', author: '约翰·博格', source: const Value('先锋集团'), category: QuoteCategory.investment, tags: const Value('指数基金,被动')),
      QuotesCompanion.insert(content: '不要和市场先生争辩。', author: '本杰明·格雷厄姆', source: const Value('《聪明的投资者》'), category: QuoteCategory.investment, tags: const Value('市场,理性')),
      QuotesCompanion.insert(content: '投资者最大的敌人是自己内心的情绪。', author: '本杰明·格雷厄姆', source: const Value('《聪明的投资者》'), category: QuoteCategory.investment, tags: const Value('情绪,心理')),
      QuotesCompanion.insert(content: '每一天都是一个新的日子。走运当然是好的，不过我情愿做到分毫不差。', author: '欧内斯特·海明威', source: const Value('《老人与海》'), category: QuoteCategory.investment, tags: const Value('运气,准备')),
    ];

    await batch((batch) {
      batch.insertAll(quotes, classics);
      batch.insertAll(quotes, poems);
      batch.insertAll(quotes, investments);
    });
  }

  // ============ Queries ============
  Future<List<Quote>> getAllQuotes() => select(quotes).get();
  Stream<List<Quote>> watchAllQuotes() => select(quotes).watch();
  Future<List<Quote>> getQuotesByCategory(QuoteCategory category) {
    return (select(quotes)..where((q) => q.category.equals(category.index))).get();
  }
  Stream<List<Quote>> watchQuotesByCategory(QuoteCategory category) {
    return (select(quotes)..where((q) => q.category.equals(category.index))).watch();
  }
  Future<List<Quote>> getFavorites() {
    return (select(quotes)..where((q) => q.isFavorite.equals(true))).get();
  }
  Stream<List<Quote>> watchFavorites() {
    return (select(quotes)..where((q) => q.isFavorite.equals(true))).watch();
  }
  Future<void> toggleFavorite(int id, bool isFav) {
    return (update(quotes)..where((q) => q.id.equals(id)))
        .write(QuotesCompanion(isFavorite: Value(isFav)));
  }
  Future<List<Quote>> searchQuotes(String keyword) {
    return (select(quotes)
          ..where((q) =>
              q.content.like('%$keyword%') |
              q.author.like('%$keyword%') |
              q.source.like('%$keyword%') |
              q.tags.like('%$keyword%')))
        .get();
  }
  Future<Quote?> getRandomQuote() async {
    final all = await getAllQuotes();
    if (all.isEmpty) return null;
    // 优先返回未读的
    final unread = all.where((q) => !q.isRead).toList();
    if (unread.isNotEmpty) {
      unread.shuffle();
      return unread.first;
    }
    // 全部已读时随机返回
    all.shuffle();
    return all.first;
  }
  
  Future<Quote?> getRandomUnreadQuote() async {
    final all = await getAllQuotes();
    if (all.isEmpty) return null;
    final unread = all.where((q) => !q.isRead).toList();
    if (unread.isEmpty) return null;
    unread.shuffle();
    return unread.first;
  }
  
  Future<Quote?> getRandomQuoteByCategory(QuoteCategory category) async {
    final byCat = await getQuotesByCategory(category);
    if (byCat.isEmpty) return null;
    // 优先未读
    final unread = byCat.where((q) => !q.isRead).toList();
    if (unread.isNotEmpty) {
      unread.shuffle();
      return unread.first;
    }
    byCat.shuffle();
    return byCat.first;
  }
  
  Future<void> markAsRead(int id) async {
    await (update(quotes)..where((q) => q.id.equals(id)))
        .write(const QuotesCompanion(isRead: Value(true)));
  }

  // Import/Export
  Future<void> importQuotes(List<Map<String, dynamic>> data) async {
    final toInsert = data.map((item) => QuotesCompanion.insert(
      content: item['content'] ?? '',
      author: item['author'] ?? 'Unknown',
      source: Value(item['source']),
      category: QuoteCategory.values[item['category'] ?? 0],
      tags: Value(item['tags'] ?? ''),
    )).toList();
    await batch((batch) => batch.insertAll(quotes, toInsert));
  }

  Future<void> insertQuote(Map<String, dynamic> data) async {
    await into(quotes).insert(QuotesCompanion.insert(
      content: data['content'] ?? '',
      author: data['author'] ?? 'Unknown',
      source: Value(data['source'] ?? ''),
      category: QuoteCategory.values[data['category'] ?? 0],
      tags: Value(data['tags'] ?? ''),
    ));
  }

  Future<void> updateQuoteNotes(int id, String notes) async {
    await (update(quotes)..where((q) => q.id.equals(id)))
        .write(QuotesCompanion(notes: Value(notes)));
  }

  Future<void> updateQuote(int id, Map<String, dynamic> data) async {
    await (update(quotes)..where((q) => q.id.equals(id)))
        .write(QuotesCompanion(
          content: Value(data['content'] ?? ''),
          author: Value(data['author'] ?? ''),
          source: Value(data['source'] ?? ''),
          tags: Value(data['tags'] ?? ''),
          notes: Value(data['notes'] ?? ''),
        ));
  }

  // ============ My Thoughts (吾思) - 使用 Quotes 表，author='吾思' 标识 ============
  Future<List<Quote>> getAllMyThoughts() {
    return (select(quotes)..where((q) => q.author.equals('吾思'))).get();
  }
  
  Future<void> insertMyThought(Map<String, dynamic> data) async {
    await into(quotes).insert(QuotesCompanion.insert(
      content: data['content'] ?? '',
      author: '吾思',
      source: const Value(''),
      category: QuoteCategory.classicLiterature,
      tags: Value(data['tags'] ?? ''),
      notes: Value(data['notes'] ?? ''),
    ));
  }

  Future<void> updateMyThought(int id, Map<String, dynamic> data) async {
    await (update(quotes)..where((q) => q.id.equals(id)))
        .write(QuotesCompanion(
          content: Value(data['content'] ?? ''),
          tags: Value(data['tags'] ?? ''),
          notes: Value(data['notes'] ?? ''),
        ));
  }

  Future<void> deleteMyThought(int id) async {
    await (delete(quotes)..where((q) => q.id.equals(id))).go();
  }

  Future<List<Map<String, dynamic>>> exportMyThoughts() async {
    final all = await getAllMyThoughts();
    return all.map((t) => {
      'content': t.content,
      'author': t.author,
      'tags': t.tags,
      'notes': t.notes,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> exportQuotes() async {
    final all = await getAllQuotes();
    return all.map((q) => {
      'content': q.content,
      'author': q.author,
      'source': q.source,
      'category': q.category.index,
      'tags': q.tags,
      'notes': q.notes,
      'isFavorite': q.isFavorite,
    }).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wisdom_quotes.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

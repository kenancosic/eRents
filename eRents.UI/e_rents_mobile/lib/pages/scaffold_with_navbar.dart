import 'package:dart_amqp/dart_amqp.dart';
import 'package:e_rents_mobile/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar(
      {super.key, required this.child, required this.location});

  final Widget child;
  final String location;
  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  Client client = Client(
      settings: ConnectionSettings(
          host:
              const String.fromEnvironment("mqHost", defaultValue: "localhost"),
          authProvider: const PlainAuthenticator(
              String.fromEnvironment("mqUsername", defaultValue: "user"),
              String.fromEnvironment("mqPass", defaultValue: "mypass"))));

  @override
  void initState() {
    super.initState();
    // checkNotifications();
  }

  Future<void> checkNotifications() async {
    Channel channel = await client
        .channel(); // auto-connect to localhost:5672 using guest credentials
    Queue queue = await channel.queue("trip_added");
    var consumer = await queue.consume();
    consumer.listen((AmqpMessage message) {
      ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.showSuccessSnackBar(message.payloadAsString));
    });
  }

  static List<MyCustomBottomNavBarItem> tabs = [
    const MyCustomBottomNavBarItem(
        initialLocation: "/home",
        label: "Home",
        icon: Icon(
          FontAwesomeIcons.house,
          color: Color(0xffBBBBBB),
        ),
        activeIcon: Icon(
          FontAwesomeIcons.house,
          color: Color.fromARGB(255, 226, 136, 214),
        )),
    const MyCustomBottomNavBarItem(
        initialLocation: '/bookmarks',
        label: 'Bookmarks',
        icon: Icon(FontAwesomeIcons.bookmark, color: Color(0xffBBBBBB)),
        activeIcon: Icon(
          FontAwesomeIcons.bookmark,
          color: Color.fromARGB(255, 226, 136, 214),
        )),
    const MyCustomBottomNavBarItem(
        initialLocation: "/search",
        label: "search",
        icon: Icon(FontAwesomeIcons.magnifyingGlass, color: Color(0xffBBBBBB)),
        activeIcon: Icon(
          FontAwesomeIcons.magnifyingGlass,
          color: Color.fromARGB(255, 226, 136, 214),
        )),
    const MyCustomBottomNavBarItem(
        initialLocation: "/profile",
        label: "Profile",
        // icon: Container(
        //   height: 28,
        //   width: 28,
        //   decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(28),
        //     image: const DecorationImage(
        //         image: AssetImage("assets/images/user-image.png"),
        //         fit: BoxFit.cover),
        //     border: Border.all(
        //         width: 1,
        //         color: const Color(0xffFFD69D),
        //         strokeAlign: BorderSide.strokeAlignCenter),
        //   ),
        icon:
            Icon(FontAwesomeIcons.idBadge, size: 28, color: Color(0xffBBBBBB)),
        activeIcon: Icon(
          FontAwesomeIcons.idBadge,
          color: Color.fromARGB(255, 226, 136, 214),
          size: 28,
        )),
    // activeIcon: Container(
    //   height: 28,
    //   width: 28,
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(28),
    //     image: const DecorationImage(
    //         image: AssetImage("assets/images/user-image.png"),
    //         fit: BoxFit.cover),
    //     border: Border.all(
    //         width: 3,
    //         color: const Color(0xffFFD69D),
    //         strokeAlign: BorderSide.strokeAlignCenter),
    //   ),
    // ),
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0 && context.canPop()) {
            context.pop();
          }
        },
        child: widget.child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 3,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: const Color.fromARGB(255, 226, 136, 214),
        unselectedItemColor: const Color(0xffBBBBBB),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (int index) {
          _goOtherTab(context, index);
        },
        currentIndex: widget.location == '/bookmarks'
            ? 1
            : widget.location == '/search'
                ? 2
                : widget.location == '/profile'
                    ? 3
                    : 0,
        items: tabs,
      ),
    );
  }

  void _goOtherTab(BuildContext context, int index) {
    // if (index == _currentIndex && index != 2) return;
    GoRouter router = GoRouter.of(context);
    String location = tabs[index].initialLocation;

    setState(() {});
    if (index == 0) {
      router.go("/home");
    } else if (index == 3) {
      router.go("/profile");
    } else {
      router.go(location);
    }
  }
}

class MyCustomBottomNavBarItem extends BottomNavigationBarItem {
  final String initialLocation;

  const MyCustomBottomNavBarItem(
      {required this.initialLocation,
      required Icon super.icon,
      super.label,
      Icon? super.activeIcon});
}

import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import '../../routes/base_screen.dart';

class PropertyListScreen extends StatefulWidget {
  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreProperties();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoadingMore) {
      _loadMoreProperties();
    }
  }

  Future<void> _loadMoreProperties() async {
    setState(() {
      _isLoadingMore = true;
    });

    await Provider.of<PropertyProvider>(context, listen: false).fetchProperties(page: _page);
    setState(() {
      _page++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Properties',
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Busy && _page == 1) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: provider.properties.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.properties.length) {
                return _isLoadingMore ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
              }
              final property = provider.properties[index];
              return ListTile(
                title: Text(property.name),
                subtitle: Text('${property.price} USD'),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

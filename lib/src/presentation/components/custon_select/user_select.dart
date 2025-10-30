import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:flutter/material.dart';

class UserSelect extends StatefulWidget {
  final Function(User) onUserSelected;
  final bool enabled;
  final User? initialUser;
  final String? searchQuery;

  const UserSelect({
    super.key,
    required this.onUserSelected,
    this.enabled = true,
    this.initialUser,
    this.searchQuery,
  });

  @override
  _UserSelectState createState() => _UserSelectState();
}

class _UserSelectState extends State<UserSelect> {
  List<User> users = [];
  List<User> filteredUsers = [];
  User? selectedUser;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  bool isExpanded = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    selectedUser = widget.initialUser;
    
    _searchController.addListener(_filterUsers);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !isExpanded) {
      toggleOverlay();
    }
  }

  Future<void> fetchUsers() async {
    try {
      ApiServices apiServices = ApiServices();
      List<User> fetchedUsers = await apiServices.fetchAllUsers();
      setState(() {
        users = fetchedUsers;
        filteredUsers = fetchedUsers;
      });
    } catch (e) {
      print('Error al cargar los usuarios: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final fullName = '${user.name?.firstname ?? ''} ${user.name?.lastname ?? ''}'.toLowerCase();
          final email = user.email.toLowerCase();
          final username = user.username.toLowerCase();
          
          return fullName.contains(query) || 
                 email.contains(query) || 
                 username.contains(query);
        }).toList();
      }
    });
  }

  void toggleOverlay() {
    if (!widget.enabled) return;

    if (isExpanded) {
      _overlayEntry?.remove();
      isExpanded = false;
      _focusNode.unfocus();
    } else {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      isExpanded = true;
      _focusNode.requestFocus();
    }
    setState(() {});
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No se encontraron clientes'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return ListTile(
                              title: Text('${user.name?.firstname} ${user.name?.lastname}'),
                              subtitle: Text(user.email),
                              onTap: () {
                                setState(() {
                                  selectedUser = user;
                                  _searchController.clear();
                                });
                                widget.onUserSelected(user);
                                toggleOverlay();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        readOnly: true,
        onTap: widget.enabled ? toggleOverlay : null,
        decoration: InputDecoration(
          hintText: selectedUser != null
              ? '${selectedUser!.name?.firstname} ${selectedUser!.name?.lastname}'
              : 'Seleccionar cliente...',
          hintStyle: TextStyle(
            color: widget.enabled ? Colors.black : Colors.grey,
          ),
          prefixIcon: Icon(Icons.person_outline,
              color: widget.enabled ? Colors.grey : Colors.grey[400]),
          suffixIcon: IconButton(
            icon: Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: widget.enabled ? Colors.black : Colors.grey[400],
            ),
            onPressed: widget.enabled ? toggleOverlay : null,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          fillColor: widget.enabled ? Colors.white : Colors.grey[200],
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(
          color: widget.enabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }
}
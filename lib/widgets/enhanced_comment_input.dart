import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment_info.dart';
import '../services/comment_state_service.dart';
import '../widgets/emote_panel.dart';

/// 增强评论输入框 - 参考BLVD项目
class EnhancedCommentInput extends StatefulWidget {
  final String oid;
  final String? parentRpid;
  final String? placeholder;
  final bool autofocus;
  final int? maxLength;
  final Function(String)? onTextChanged;
  final VoidCallback? onSend;
  final VoidCallback? onEmoteSelected;

  const EnhancedCommentInput({
    Key? key,
    required this.oid,
    this.parentRpid,
    this.placeholder,
    this.autofocus = false,
    this.maxLength,
    this.onTextChanged,
    this.onSend,
    this.onEmoteSelected,
  }) : super(key: key);

  @override
  State<EnhancedCommentInput> createState() => _EnhancedCommentInputState();
}

class _EnhancedCommentInputState extends State<EnhancedCommentInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isComposing = false;
  bool _showEmotePanel = false;
  bool _isAtMode = false;
  String _atSearchQuery = '';
  List<UserSuggestion> _userSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()
      ..addListener(_onTextChanged);
    _focusNode = FocusNode()
      ..addListener(_onFocusChanged);
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final wasComposing = _isComposing;
    _isComposing = text.isNotEmpty;

    // 检测@模式
    _updateAtMode(text);

    if (wasComposing != _isComposing) {
      setState(() {});
    }

    widget.onTextChanged?.call(text);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _showEmotePanel = false;
      _isAtMode = false;
      setState(() {});
    }
  }

  void _updateAtMode(String text) {
    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) return;

    // 查找光标前最近的@符号
    int atPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atPos = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atPos != -1 && cursorPos - atPos - 1 <= 20) {
      _atSearchQuery = text.substring(atPos + 1, cursorPos);
      _isAtMode = true;
      _searchUsers(_atSearchQuery);
    } else {
      _isAtMode = false;
      _atSearchQuery = '';
      _userSuggestions.clear();
    }

    if (_isAtMode != mounted) {
      setState(() {});
    }
  }

  void _searchUsers(String query) {
    // 模拟用户搜索
    // 实际项目中应该调用API搜索用户
    final mockUsers = [
      UserSuggestion('123456', '用户A', ''),
      UserSuggestion('234567', '用户B', ''),
      UserSuggestion('345678', '用户C', ''),
    ];

    setState(() {
      _userSuggestions = mockUsers
          .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentStateService = Provider.of<CommentStateService>(context);
    final canSend = commentStateService.isOnline && _isComposing;

    return Column(
      children: [
        if (_showEmotePanel)
          _buildEmotePanel(),
        if (_isAtMode && _userSuggestions.isNotEmpty)
          _buildUserSuggestions(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildInputRow(canSend),
              if (!commentStateService.isOnline)
                _buildOfflineMessage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotePanel() {
    return EmotePanel(
      searchText: null,
      onEmoteSelected: (emote) {
        _insertText(emote.text);
        widget.onEmoteSelected?.call();
      },
    );
  }

  Widget _buildUserSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _userSuggestions.length,
        itemBuilder: (context, index) {
          final user = _userSuggestions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.avatar),
            ),
            title: Text(user.name),
            subtitle: Text('UID: ${user.uid}'),
            onTap: () => _selectUserSuggestion(user),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(bool canSend) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: Provider.of<CommentStateService>(context).isOnline,
              maxLines: 5,
              minLines: 1,
              maxLength: widget.maxLength ?? 1000,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 
                    (Provider.of<CommentStateService>(context).isOnline 
                        ? '写下你的评论...' 
                        : '网络连接已断开'),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                counterText: '',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEmoteButton(),
                    _buildAtButton(),
                    _buildTopicButton(),
                  ],
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearText,
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: canSend ? _sendComment : null,
          icon: const Icon(Icons.send),
          style: IconButton.styleFrom(
            backgroundColor: canSend 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade400,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmoteButton() {
    return IconButton(
      icon: Icon(
        Icons.emoji_emotions_outlined,
        color: _showEmotePanel 
            ? Theme.of(context).primaryColor 
            : Colors.grey.shade600,
      ),
      onPressed: () {
        setState(() {
          _showEmotePanel = !_showEmotePanel;
          if (_showEmotePanel) {
            _isAtMode = false;
          }
        });
      },
    );
  }

  Widget _buildAtButton() {
    return IconButton(
      icon: Icon(
        Icons.alternate_email,
        color: _isAtMode 
            ? Theme.of(context).primaryColor 
            : Colors.grey.shade600,
      ),
      onPressed: _insertAtSymbol,
    );
  }

  Widget _buildTopicButton() {
    return IconButton(
      icon: Icon(
        Icons.tag,
        color: Colors.grey.shade600,
      ),
      onPressed: _insertTopicSymbol,
    );
  }

  Widget _buildOfflineMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Text(
            '网络连接已断开，检查网络后可恢复发送',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _insertText(String text) {
    final cursorPos = _controller.selection.baseOffset;
    final currentText = _controller.text;
    
    // 如果在@模式下，替换@符号后的内容
    if (_isAtMode && _atSearchQuery.isNotEmpty) {
      final atPos = currentText.lastIndexOf('@', cursorPos);
      if (atPos != -1) {
        final newText = currentText.replaceRange(atPos + 1, cursorPos, text);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: atPos + 1 + text.length),
        );
        _isAtMode = false;
        return;
      }
    }
    
    // 正常插入文本
    final newText = currentText.replaceRange(
      cursorPos,
      _controller.selection.extentOffset,
      text,
    );
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos + text.length),
    );
  }

  void _insertAtSymbol() {
    _insertText('@');
  }

  void _insertTopicSymbol() {
    _insertText('# #');
    final cursorPos = _controller.selection.baseOffset;
    _controller.selection = TextSelection.collapsed(offset: cursorPos - 1);
  }

  void _selectUserSuggestion(UserSuggestion user) {
    final cursorPos = _controller.selection.baseOffset;
    final currentText = _controller.text;
    
    // 找到@符号位置
    int atPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (currentText[i] == '@') {
        atPos = i;
        break;
      }
    }
    
    if (atPos != -1) {
      final newText = currentText.replaceRange(atPos, cursorPos, '@${user.name} ');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: atPos + user.name.length + 2),
      );
    }
    
    setState(() {
      _isAtMode = false;
      _atSearchQuery = '';
      _userSuggestions.clear();
    });
  }

  void _clearText() {
    _controller.clear();
    setState(() {
      _isComposing = false;
      _isAtMode = false;
      _atSearchQuery = '';
      _userSuggestions.clear();
    });
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final commentStateService = Provider.of<CommentStateService>(context, listen: false);
      await commentStateService.sendComment(
        oid: widget.oid,
        message: text,
        parentRpid: widget.parentRpid,
      );

      _controller.clear();
      setState(() {
        _isComposing = false;
      });

      widget.onSend?.call();
    } catch (e) {
      _showErrorSnackBar('发送失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// 用户建议
class UserSuggestion {
  final String uid;
  final String name;
  final String avatar;

  UserSuggestion(this.uid, this.name, this.avatar);
}
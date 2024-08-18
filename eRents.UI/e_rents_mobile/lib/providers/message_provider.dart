import 'dart:convert';
import 'package:e_rents_mobile/models/message.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';

class MessageProvider extends BaseProvider<Message> {
  MessageProvider() : super("Messages");

  @override
  Message fromJson(data) {
    return Message.fromJson(data);
  }

  Future<Message?> getMessageById(int id) async {
    try {
      return await getById(id);
    } catch (e) {
      logError(e, 'getMessageById');
      rethrow;
    }
  }

  Future<List<Message>> getMessages({dynamic search}) async {
    try {
      return await get(search: search);
    } catch (e) {
      logError(e, 'getMessages');
      rethrow;
    }
  }

  Future<Message?> createMessage(Message message) async {
    try {
      return await insert(message);
    } catch (e) {
      logError(e, 'createMessage');
      rethrow;
    }
  }

  Future<Message?> updateMessage(int id, Message message) async {
    try {
      return await update(id, message);
    } catch (e) {
      logError(e, 'updateMessage');
      rethrow;
    }
  }

  Future<bool> deleteMessage(int id) async {
    try {
      return await delete(id);
    } catch (e) {
      logError(e, 'deleteMessage');
      rethrow;
    }
  }
}

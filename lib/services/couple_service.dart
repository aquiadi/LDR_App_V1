import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/supabase_client.dart';
import '../models/couple_model.dart';
import '../models/user_model.dart';

part 'couple_service.g.dart';

@riverpod
CoupleService coupleService(CoupleServiceRef ref) {
  return CoupleService(ref.watch(supabaseClientProvider));
}

class CoupleService {
  final SupabaseClient _supabase;

  CoupleService(this._supabase);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Creates a new shared space owned by the signed-in user.
  ///
  /// If the user already belongs to a *fully formed* couple this refuses
  /// rather than proceeding: the previous implementation deleted the existing
  /// couple row first, which cascaded away every check-in the pair had ever
  /// written and silently unpaired the partner.
  Future<CoupleModel> createCouple({
    String? spaceName,
    DateTime? anniversaryDate,
    String? welcomeMessage,
    String? coverPhotoUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final existing = await getCurrentCouple();
    if (existing != null) {
      if (existing.partner1Id != null && existing.partner2Id != null) {
        throw Exception(
          'You are already paired. Leave your current space before creating a new one.',
        );
      }
      // A space that is still waiting on a partner is simply reused, so the
      // invite code the user may already have shared stays valid.
      return existing;
    }

    final couple = await _insertCoupleWithUniqueCode(
      userId: user.id,
      spaceName: spaceName,
      anniversaryDate: anniversaryDate,
      welcomeMessage: welcomeMessage,
      coverPhotoUrl: coverPhotoUrl,
    );

    await _supabase.from('users').update({
      'couple_id': couple.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);

    return couple;
  }

  /// `couples.invite_code` is UNIQUE, so a collision is a real (if unlikely)
  /// outcome of an 8-character random code. Retry a bounded number of times
  /// instead of surfacing a raw constraint violation.
  Future<CoupleModel> _insertCoupleWithUniqueCode({
    required String userId,
    String? spaceName,
    DateTime? anniversaryDate,
    String? welcomeMessage,
    String? coverPhotoUrl,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _supabase.from('couples').insert({
          'invite_code': _generateInviteCode(),
          'partner_1_id': userId,
          'is_active': true,
          'space_name': spaceName,
          // anniversary_date is a DATE column; send a plain calendar date.
          'anniversary_date':
              anniversaryDate?.toIso8601String().split('T').first,
          'welcome_message': welcomeMessage,
          'cover_photo_url': coverPhotoUrl,
        }).select().single();
        return CoupleModel.fromJson(response);
      } on PostgrestException catch (e) {
        // 23505 = unique_violation
        if (e.code == '23505' && attempt < maxAttempts) continue;
        rethrow;
      }
    }
    throw Exception('Could not allocate a unique invite code. Please try again.');
  }

  /// The couple the signed-in user currently belongs to, or null.
  Future<CoupleModel?> getCurrentCouple() async {
    final profile = await getCurrentUserProfile();
    final coupleId = profile?.coupleId;
    if (coupleId == null) return null;

    final response =
        await _supabase.from('couples').select().eq('id', coupleId).maybeSingle();
    if (response == null) return null;
    return CoupleModel.fromJson(response);
  }

  Future<CoupleModel> joinCouple(String inviteCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      final response = await _supabase.rpc('join_couple', params: {
        'invite_code_input': inviteCode.trim().toUpperCase(),
      });

      if (response == null) {
        throw Exception('Invalid invite code. Please check and try again.');
      }
      return CoupleModel.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      if (e.toString().contains('Invalid invite code')) {
        throw Exception('Invalid invite code. Please check and try again.');
      } else if (e.toString().contains('already full')) {
        throw Exception('This couple is already full.');
      } else if (e.toString().contains('already in this couple')) {
        throw Exception('You are already in this couple.');
      }
      throw Exception('Failed to join couple: $e');
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }
}

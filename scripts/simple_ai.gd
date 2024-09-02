class_name SimpleAI extends EnemyAI;

func get_move() -> MoveInstance:
	var moves := parent.get_legal_moves();
	var player_pos := parent.map.player.pos;
	if len(moves) == 0:
		return null;

	var best_move: MoveInstance = moves[0];
	for move in moves:
		if abs(move.end_position.x - player_pos.x) + abs(move.end_position.y - player_pos.y) < abs(best_move.end_position.x - player_pos.x) + abs(best_move.end_position.y - player_pos.y):
			best_move = move;

	return best_move;

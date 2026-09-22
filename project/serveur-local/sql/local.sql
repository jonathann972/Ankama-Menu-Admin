ALTER TABLE giny_auth.accounts CHANGE CharactersSlots CharacterSlots int DEFAULT 15;
UPDATE giny_auth.accounts SET Nickname='Local', CharacterSlots=20 WHERE Id=1;
DELETE FROM giny_auth.world_servers WHERE Id=50;

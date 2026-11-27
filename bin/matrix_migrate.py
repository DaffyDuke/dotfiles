#!/usr/bin/env python3
"""
Matrix Account Migration Helper
Permet d'exporter les salons rejoints depuis un ancien compte Matrix
et d'inviter ou faire rejoindre ces salons par un nouveau compte.

Prérequis : python3, requests (ou urllib standard)
"""

import argparse
import json
import sys
import urllib.parse
import urllib.request
import urllib.error

def normalize_homeserver(url: str) -> str:
    url = url.strip()
    if not url.startswith("http://") and not url.startswith("https://"):
        url = "https://" + url
    return url.rstrip("/")

def api_request(homeserver: str, endpoint: str, token: str, method: str = "GET", data: dict = None):
    base_url = normalize_homeserver(homeserver)
    url = f"{base_url}/_matrix/client/v3/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    req_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            return {"error": True, "status": e.code, "body": json.loads(err_body)}
        except Exception:
            return {"error": True, "status": e.code, "body": err_body}
    except Exception as e:
        return {"error": True, "status": 0, "message": str(e)}

def export_rooms(homeserver: str, token: str, output_file: str):
    print(f"[*] Récupération des salons depuis {homeserver}...")
    res = api_request(homeserver, "joined_rooms", token)
    if "error" in res:
        print(f"[!] Erreur lors de la récupération des salons: {res}")
        sys.exit(1)

    room_ids = res.get("joined_rooms", [])
    print(f"[+] {len(room_ids)} salons trouvés.")

    rooms_detail = []
    for idx, room_id in enumerate(room_ids, start=1):
        # Récupérer les métadonnées (nom, alias)
        name_res = api_request(homeserver, f"rooms/{room_id}/state/m.room.name", token)
        room_name = name_res.get("name") if "error" not in name_res else None

        alias_res = api_request(homeserver, f"rooms/{room_id}/state/m.room.canonical_alias", token)
        room_alias = alias_res.get("alias") if "error" not in alias_res else None

        join_rules_res = api_request(homeserver, f"rooms/{room_id}/state/m.room.join_rules", token)
        join_rule = join_rules_res.get("join_rule", "unknown") if "error" not in join_rules_res else "unknown"

        rooms_detail.append({
            "room_id": room_id,
            "name": room_name,
            "alias": room_alias,
            "join_rule": join_rule
        })
        print(f"  [{idx}/{len(room_ids)}] {room_alias or room_name or room_id} ({join_rule})")

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(rooms_detail, f, indent=2, ensure_ascii=False)

    print(f"\n[+] Export terminé avec succès dans {output_file}")

def invite_or_join(source_hs: str, source_token: str, target_hs: str, target_token: str, new_user_id: str, rooms_file: str):
    with open(rooms_file, "r", encoding="utf-8") as f:
        rooms = json.load(f)

    print(f"[*] Traitement de {len(rooms)} salons pour le compte {new_user_id}...")

    for room in rooms:
        room_id = room["room_id"]
        display = room["alias"] or room["name"] or room_id
        join_rule = room.get("join_rule")

        print(f"\n--> Salon : {display} ({join_rule})")

        if join_rule == "public":
            # Le nouveau compte peut directement rejoindre
            target_to_join = room["alias"] or room_id
            print(f"    Rejoindre directement via {target_hs}...")
            # Encodage URL impératif (# devient %23, ! devient %21)
            escaped_target = urllib.parse.quote(target_to_join, safe="")
            # On passe server_name=matrix.org en paramètre pour assister la fédération
            join_endpoint = f"join/{escaped_target}?server_name=matrix.org"
            res = api_request(target_hs, join_endpoint, target_token, method="POST", data={})
            if "error" in res:
                err_msg = res.get("body", {}).get("error") if isinstance(res.get("body"), dict) else res.get("body")
                err_code = res.get("body", {}).get("errcode") if isinstance(res.get("body"), dict) else res.get("status")
                print(f"    [!] Échec adhésion ({err_code}) : {err_msg or res}")
            else:
                print(f"    [✓] Rejoint avec succès !")
        else:
            # Salon privé / invite-only : l'ancien compte doit inviter le nouveau
            print(f"    Envoi d'invitation depuis {source_hs} vers {new_user_id}...")
            escaped_room_id = urllib.parse.quote(room_id, safe="")
            inv_res = api_request(source_hs, f"rooms/{escaped_room_id}/invite", source_token, method="POST", data={"user_id": new_user_id})
            if "error" in inv_res:
                err_msg = inv_res.get("body", {}).get("error") if isinstance(inv_res.get("body"), dict) else inv_res.get("body")
                print(f"    [!] Échec invitation : {err_msg or inv_res}")
            else:
                print(f"    [+] Invitation envoyée. Acceptation via {target_hs}...")
                join_endpoint = f"join/{escaped_room_id}?server_name=matrix.org"
                join_res = api_request(target_hs, join_endpoint, target_token, method="POST", data={})
                if "error" in join_res:
                    err_msg = join_res.get("body", {}).get("error") if isinstance(join_res.get("body"), dict) else join_res.get("body")
                    print(f"    [!] Échec acceptation : {err_msg or join_res}")
                else:
                    print(f"    [✓] Invitation acceptée !")

def main():
    main_epilog = """Exemples d'utilisation :

  1) Exporter les salons depuis l'ancien compte :
     matrix_migrate.py export --token "syt_oldtoken..."

  2) Migrer les salons vers le nouveau compte :
     matrix_migrate.py migrate \\
       --source-token "syt_oldtoken..." \\
       --target-homeserver "https://matrix.newserver.org" \\
       --target-token "syt_newtoken..." \\
       --new-user "@alice:newserver.org"
"""

    parser = argparse.ArgumentParser(
        description="Matrix Account Migration Helper",
        epilog=main_epilog,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Commande Export
    export_epilog = """Exemples :
  # Export avec le homeserver source par défaut (https://matrix.org) :
  matrix_migrate.py export --token "syt_oldtoken..."

  # Export en spécifiant un homeserver personnalisé et un fichier de sortie :
  matrix_migrate.py export --homeserver matrix.org --token "syt_oldtoken..." --out mes_salons.json
"""
    p_export = subparsers.add_parser(
        "export",
        help="Exporter la liste des salons",
        epilog=export_epilog,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p_export.add_argument("--homeserver", default="https://matrix-client.matrix.org", help="URL du homeserver source (défaut: matrix.org)")
    p_export.add_argument("--token", required=True, help="Access Token du compte source")
    p_export.add_argument("--out", default="matrix_rooms.json", help="Fichier de sortie JSON (défaut: matrix_rooms.json)")

    # Commande Migrate / Rejoin
    migrate_epilog = """Exemples :
  # Migration vers le nouveau homeserver (avec rooms par défaut matrix_rooms.json) :
  matrix_migrate.py migrate \\
    --source-token "syt_oldtoken..." \\
    --target-homeserver "https://matrix.newserver.org" \\
    --target-token "syt_newtoken..." \\
    --new-user "@alice:newserver.org"

  # En précisant un fichier de salons personnalisé :
  matrix_migrate.py migrate \\
    --source-token "syt_oldtoken..." \\
    --target-homeserver "https://matrix.newserver.org" \\
    --target-token "syt_newtoken..." \\
    --new-user "@alice:newserver.org" \\
    --rooms mes_salons.json
"""
    p_migrate = subparsers.add_parser(
        "migrate",
        help="Inviter ou faire rejoindre les salons sur le nouveau compte",
        epilog=migrate_epilog,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p_migrate.add_argument("--source-homeserver", default="https://matrix-client.matrix.org", help="Homeserver de l'ancien compte (défaut: matrix.org)")
    p_migrate.add_argument("--source-token", required=True, help="Access Token de l'ancien compte")
    p_migrate.add_argument("--target-homeserver", required=True, help="URL du homeserver cible (ex: https://matrix.newserver.org)")
    p_migrate.add_argument("--target-token", required=True, help="Access Token du nouveau compte")
    p_migrate.add_argument("--new-user", required=True, help="ID complet du nouveau compte (ex: @alice:newserver.org)")
    p_migrate.add_argument("--rooms", default="matrix_rooms.json", help="Fichier JSON des salons exportés (défaut: matrix_rooms.json)")

    args = parser.parse_args()

    if args.command == "export":
        export_rooms(args.homeserver, args.token, args.out)
    elif args.command == "migrate":
        invite_or_join(args.source_homeserver, args.source_token, args.target_homeserver, args.target_token, args.new_user, args.rooms)

if __name__ == "__main__":
    main()

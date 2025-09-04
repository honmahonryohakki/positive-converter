#!/usr/bin/env python3
"""
Google Play Console への自動デプロイスクリプト
Google Play Developer API を使用してApp Bundleをアップロード
"""

import os
import sys
import json
import argparse
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2 import service_account

def upload_to_play_console(
    service_account_json,
    package_name,
    bundle_path,
    track='internal',
    release_notes=None
):
    """
    Google Play Console にApp Bundleをアップロード
    
    Args:
        service_account_json: サービスアカウントのJSON
        package_name: アプリのパッケージ名
        bundle_path: AABファイルのパス
        track: リリーストラック (internal/alpha/beta/production)
        release_notes: リリースノート
    """
    
    # 認証情報を設定
    credentials = service_account.Credentials.from_service_account_info(
        json.loads(service_account_json),
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    
    # Google Play Developer API クライアントを作成
    service = build('androidpublisher', 'v3', credentials=credentials)
    
    try:
        # 編集セッションを開始
        edit_request = service.edits().insert(
            packageName=package_name,
            body={}
        )
        edit_response = edit_request.execute()
        edit_id = edit_response['id']
        
        print(f"編集セッション開始: {edit_id}")
        
        # App Bundleをアップロード
        bundle_upload = MediaFileUpload(
            bundle_path,
            mimetype='application/octet-stream',
            resumable=True
        )
        
        upload_request = service.edits().bundles().upload(
            editId=edit_id,
            packageName=package_name,
            media_body=bundle_upload
        )
        upload_response = upload_request.execute()
        version_code = upload_response['versionCode']
        
        print(f"App Bundle アップロード完了: バージョンコード {version_code}")
        
        # リリーストラックを設定
        track_config = {
            'track': track,
            'releases': [{
                'versionCodes': [version_code],
                'status': 'completed' if track == 'production' else 'draft',
                'releaseNotes': []
            }]
        }
        
        # リリースノートを追加
        if release_notes:
            track_config['releases'][0]['releaseNotes'].append({
                'language': 'ja-JP',
                'text': release_notes
            })
            track_config['releases'][0]['releaseNotes'].append({
                'language': 'en-US',
                'text': release_notes
            })
        
        # トラックを更新
        track_request = service.edits().tracks().update(
            editId=edit_id,
            packageName=package_name,
            track=track,
            body=track_config
        )
        track_response = track_request.execute()
        
        print(f"トラック '{track}' に設定完了")
        
        # 変更をコミット
        commit_request = service.edits().commit(
            editId=edit_id,
            packageName=package_name
        )
        commit_response = commit_request.execute()
        
        print("Google Play Console へのアップロード成功！")
        print(f"パッケージ: {package_name}")
        print(f"バージョンコード: {version_code}")
        print(f"トラック: {track}")
        
        return True
        
    except Exception as e:
        print(f"エラーが発生しました: {e}", file=sys.stderr)
        
        # エラー時は編集をキャンセル
        try:
            service.edits().delete(
                editId=edit_id,
                packageName=package_name
            ).execute()
        except:
            pass
        
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Google Play Console への自動デプロイ'
    )
    parser.add_argument(
        '--bundle',
        required=True,
        help='App Bundle (.aab) ファイルのパス'
    )
    parser.add_argument(
        '--package-name',
        required=True,
        help='アプリのパッケージ名 (例: com.positive.converter)'
    )
    parser.add_argument(
        '--track',
        default='internal',
        choices=['internal', 'alpha', 'beta', 'production'],
        help='リリーストラック'
    )
    parser.add_argument(
        '--release-notes',
        help='リリースノート'
    )
    
    args = parser.parse_args()
    
    # サービスアカウントキーを環境変数から取得
    service_account_json = os.environ.get('GOOGLE_PLAY_SERVICE_ACCOUNT_KEY')
    if not service_account_json:
        print("エラー: GOOGLE_PLAY_SERVICE_ACCOUNT_KEY が設定されていません", file=sys.stderr)
        sys.exit(1)
    
    # アップロード実行
    success = upload_to_play_console(
        service_account_json=service_account_json,
        package_name=args.package_name,
        bundle_path=args.bundle,
        track=args.track,
        release_notes=args.release_notes
    )
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
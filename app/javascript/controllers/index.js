import { application } from "./application";

import AnnouncementsController from "./announcements_controller";
import LiveStreamsController from "./live_streams_controller";
import ProfileBadgeController from "./profile_badge_controller";
import ProfilesController from "./profiles_controller";
import PushNotificationController from "./push_notification_controller";
import SignageDevicesController from "./signage_devices_controller";
import SignagesController from "./signages_controller";
import SubscreenController from "./subscreen_controller";
import SubscreenOnStreamsController from "./subscreen_on_streams_controller";
import TalkBookmarksController from "./talk_bookmarks_controller";
import UsersController from "./users_controller";
import AdminProfileBadgeController from "./admin/profile_badge_controller";

application.register("announcements", AnnouncementsController);
application.register("live-streams", LiveStreamsController);
application.register("profile-badge", ProfileBadgeController);
application.register("profiles", ProfilesController);
application.register("push-notification", PushNotificationController);
application.register("signage-devices", SignageDevicesController);
application.register("signages", SignagesController);
application.register("subscreen", SubscreenController);
application.register("subscreen-on-streams", SubscreenOnStreamsController);
application.register("talk-bookmarks", TalkBookmarksController);
application.register("users", UsersController);
application.register("admin--profile-badge", AdminProfileBadgeController);

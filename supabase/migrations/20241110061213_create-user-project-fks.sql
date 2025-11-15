ALTER TABLE user_project
ADD CONSTRAINT fk_user_project_project_id_to_project_id
FOREIGN KEY (project_id) REFERENCES project(id);

ALTER TABLE user_project
ADD CONSTRAINT fk_user_project_user_id_to_profile_user_id
FOREIGN KEY (user_id) REFERENCES profile(user_id);

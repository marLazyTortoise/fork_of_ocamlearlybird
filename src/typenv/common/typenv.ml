(**
 * Copyright (C) 2021 Yuxiang Wen
 * Copyright (C) 2023 Simmo Saan
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

let persistent_env_get_search_dirs = ref ((fun _ -> assert false) : string -> string list)

let () =
  let old_load = !Persistent_env.Persistent_signature.load in
  Persistent_env.Persistent_signature.load := (fun ~unit_name ->
      let search_dirs = !persistent_env_get_search_dirs unit_name in
      Load_path.init search_dirs;
      old_load ~unit_name
    )

let env_extract_values path env =
  Env.fold_values (fun name _ _ acc -> name :: acc) path env []

let env_extract_modules path env =
  Env.fold_modules (fun name _ _ acc -> name :: acc) path env []

let env_is_structure_module path env =
  match Env.find_module path env with
  | {md_type; _} ->
    begin match Env.scrape_alias env md_type with
      | Mty_signature _ -> true
      | Mty_functor _ -> false
      | Mty_alias _ | Mty_ident _ -> failwith "scrape_alias didn't work"
    end
  | exception Not_found -> false


 type t = { env : Env.t; get_search_dirs : string -> string list }

 let from_summary ~get_search_dirs summary subst =
   persistent_env_get_search_dirs := get_search_dirs;
   Envaux.reset_cache ();
   let env = Envaux.env_from_summary (Obj.magic summary) subst in
   { env; get_search_dirs }

 let find_value path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_value path env

 let find_value_by_name name { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_value_by_name name env

 let find_type path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_type path env

 let find_constructor_by_name lid { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_constructor_by_name lid env

 let find_value_address path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_value_address path env |> Obj.magic

 let find_module_address path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_module_address path env |> Obj.magic

 let find_modtype_expansion path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Env.find_modtype_expansion path env

 let is_structure_module path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   env_is_structure_module path env

 let add_module ?arg id presence mty { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   let env' = Env.add_module ?arg id presence mty env in
   { env = env'; get_search_dirs }

 let extract_modules path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   env_extract_modules path env

 let extract_values path { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   env_extract_values path env

 let type_apply { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Ctype.apply (Obj.magic env)

 let type_matches { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Ctype.does_match (Obj.magic env)

 let full_expand { env; get_search_dirs } =
   persistent_env_get_search_dirs := get_search_dirs;
   Ctype.full_expand ~may_forget_scope:false (Obj.magic env)

 (* HACK *)
 let () =
   Env.add_delayed_check_forward := Obj.magic !Ocaml_common.Env.add_delayed_check_forward;
   Env.same_constr := Obj.magic !Ocaml_common.Env.same_constr;
   Env.check_well_formed_module := Obj.magic !Ocaml_common.Env.check_well_formed_module;
   Env.check_functor_application := Obj.magic !Ocaml_common.Env.check_functor_application;
   Env.strengthen := Obj.magic !Ocaml_common.Env.strengthen;
   Env.print_longident := Obj.magic !Ocaml_common.Env.print_longident;
   Env.print_path := Obj.magic !Ocaml_common.Env.print_path;
   Ctype.package_subtype := Obj.magic !Ocaml_common.Ctype.package_subtype;
   Persistent_env.add_delayed_check_forward := Obj.magic !Ocaml_common.Persistent_env.add_delayed_check_forward;
 (* /HACK *)

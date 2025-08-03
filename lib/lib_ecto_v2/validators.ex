defmodule LibEctoV2.Validators do
  @moduledoc """
  验证模块，提供数据验证和转换的功能。

  此模块负责验证用户输入和系统生成的数据，确保数据的完整性和正确性。
  """

  @doc """
  验证请求参数是否为 map 类型。

  ## 参数

  - `params`: 要验证的参数

  ## 返回值

  - `{:ok, params}`: 如果参数是有效的 map
  - `{:error, String.t()}`: 如果参数无效

  ## 示例

      iex> LibEctoV2.Validators.validate_params(%{name: "test"})
      {:ok, %{name: "test"}}

      iex> LibEctoV2.Validators.validate_params("not a map")
      {:error, "Params must be a map"}
  """
  @spec validate_params(any()) :: {:ok, map()} | {:error, String.t()}
  def validate_params(params) when is_map(params), do: {:ok, params}
  def validate_params(_), do: {:error, "Params must be a map"}

  @doc """
  验证提供的 schema 是否是有效的 Ecto schema。

  ## 参数

  - `schema`: 要验证的 schema 模块

  ## 返回值

  - `{:ok, schema}`: 如果 schema 有效
  - `{:error, String.t()}`: 如果 schema 无效

  ## 示例

      iex> LibEctoV2.Validators.validate_schema(MyApp.User)
      {:ok, MyApp.User}
  """
  @spec validate_schema(module()) :: {:ok, module()} | {:error, String.t()}
  def validate_schema(schema) when is_atom(schema) do
    if function_exported?(schema, :__schema__, 1) do
      {:ok, schema}
    else
      {:error, "Invalid Ecto schema module: #{inspect(schema)}"}
    end
  end

  def validate_schema(schema), do: {:error, "Schema must be a module, got: #{inspect(schema)}"}

  @doc """
  验证提供的 repo 是否是有效的 Ecto repo。

  ## 参数

  - `repo`: 要验证的 repo 模块

  ## 返回值

  - `{:ok, repo}`: 如果 repo 有效
  - `{:error, String.t()}`: 如果 repo 无效

  ## 示例

      iex> LibEctoV2.Validators.validate_repo(MyApp.Repo)
      {:ok, MyApp.Repo}
  """
  @spec validate_repo(module()) :: {:ok, module()} | {:error, String.t()}
  def validate_repo(repo) when is_atom(repo) do
    if function_exported?(repo, :all, 1) and function_exported?(repo, :get, 2) do
      {:ok, repo}
    else
      {:error, "Invalid Ecto repo module: #{inspect(repo)}"}
    end
  end

  def validate_repo(repo), do: {:error, "Repo must be a module, got: #{inspect(repo)}"}

  @doc """
  验证列名是否为有效的 atom 列表或 :all。

  ## 参数

  - `columns`: 列名列表或 :all
  - `schema`: 验证列名的 schema 模块

  ## 返回值

  - `{:ok, columns}`: 如果列名有效
  - `{:error, String.t()}`: 如果列名无效

  ## 示例

      iex> LibEctoV2.Validators.validate_columns([:id, :name], MyApp.User)
      {:ok, [:id, :name]}

      iex> LibEctoV2.Validators.validate_columns(:all, MyApp.User)
      {:ok, :all}
  """
  @spec validate_columns(atom() | [atom()], module()) :: {:ok, atom() | [atom()]} | {:error, String.t()}
  def validate_columns(:all, _schema), do: {:ok, :all}

  def validate_columns(columns, schema) when is_list(columns) do
    if Enum.all?(columns, &is_atom/1) do
      schema_fields = schema.__schema__(:fields)
      invalid_columns = Enum.filter(columns, &(&1 not in schema_fields))

      if invalid_columns == [] do
        {:ok, columns}
      else
        {:error, "Invalid columns for #{inspect(schema)}: #{inspect(invalid_columns)}"}
      end
    else
      {:error, "Columns must be a list of atoms or :all"}
    end
  end

  def validate_columns(columns, _schema),
    do: {:error, "Columns must be a list of atoms or :all, got: #{inspect(columns)}"}

  @doc """
  验证过滤器列表是否有效。

  ## 参数

  - `filters`: 过滤器列表

  ## 返回值

  - `{:ok, filters}`: 如果过滤器有效
  - `{:error, String.t()}`: 如果过滤器无效

  ## 示例

      iex> LibEctoV2.Validators.validate_filters([:id, :name])
      {:ok, [:id, :name]}
  """
  @spec validate_filters(list()) :: {:ok, list()} | {:error, String.t()}
  def validate_filters(filters) when is_list(filters) do
    if Enum.all?(filters, &is_atom/1) do
      {:ok, filters}
    else
      {:error, "Filters must be a list of atoms"}
    end
  end

  def validate_filters(filters), do: {:error, "Filters must be a list, got: #{inspect(filters)}"}
end

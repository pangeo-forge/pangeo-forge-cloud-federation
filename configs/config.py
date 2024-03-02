import os

bucket_choice = os.environ.get("S3_BUCKET", "default")
bucket_options = {
    "default": "s3://pangeo-forge-veda-output"
}
s3_uri = bucket_options.get(bucket_choice)
if not s3_uri:
    raise ValueError(
        f"'S3_BUCKET_OPTIONS_MAP' did not have a key for '{bucket_choice}'. Options are {bucket_options}"
    )


def calc_task_manager_resources(task_manager_process_memory):
    """
    illustration of Flink memory model:
    https://nightlies.apache.org/flink/flink-docs-release-1.10/ops/memory/mem_detail.html#overview

    has to be sum of configured:
        Framework Heap Memory (128.000mb default) +
        Framework Off-Heap Memory (128.000mb default) +
        Managed Memory (defaults to fraction 0.4 of total flink memory) +
        Network Memory (defaults to fraction 0.1 of total flink memory but also has to between 64m and 1024m) +
        Task Heap Memory (calculated below) +
        Task Off-Heap Memory (calculated below)
    has to be below configured:
        Total Flink Memory (calculated below)
    so this quick math:
        Total Flink Memory = task_manager_process_memory - 512M
        Task Heap = (Total Flink Memory - ((0.1 * Total Flink Memory) + (0.4 * Total Flink Memory) + 128 + 128)) * 0.75
        Task Off-Heap = (Total Flink Memory - ((0.1 * Total Flink Memory) + (0.4 * Total Flink Memory) + 128 + 128)) * 0.25

    :param task_manager_process_memory:
    :return: dict of configured memory
    """

    # through testing it seems Total Flink Memory cannot
    # take up the entire Task Process Memory
    # so always give it some buffer room of 512M
    total_flink_memory = task_manager_process_memory - 512

    # as noted above:  Managed Memory (defaults to fraction 0.4 of total flink memory)
    managed_memory_ratio = 0.4
    managed_memory = int(managed_memory_ratio * total_flink_memory)

    # as noted above:  Network Memory (defaults to fraction 0.1 of total flink memory)
    # AND also has to between 64m and 1024m (we really will only run into the ceiling based on our instance sizes)
    # AND also can't be set directly b/c according to the following error b/c it's applied after all the others:
    # """
    # Caused by: org.apache.flink.configuration.IllegalConfigurationException:
    # If Total Flink, Task Heap and (or) Managed Memory sizes are explicitly configured then the
    # Network Memory size is the rest of the Total Flink memory after subtracting all
    # other configured types of memory, but the derived Network Memory is inconsistent with its configuration
    # """
    # so constrain by scaling the managed_memory_ratio
    network_memory = int(0.1 * total_flink_memory)
    if network_memory > 1024:
        leftover_network_memory = network_memory - 1024
        new_managed_memory = managed_memory + leftover_network_memory
        # adjust the managed_memory_ratio
        managed_memory_ratio = new_managed_memory / total_flink_memory
        # adjust managed_memory again with new ratio
        managed_memory = int(managed_memory_ratio * total_flink_memory)
        # scale down network memory to just below it's ceiling b/c it's fucking finicky
        network_memory = 1020

    # as noted above: Framework Heap Memory (128.000mb default)
    framework_heap_memory = 128

    # as noted above: Framework Off-Heap Memory (128.000mb default) +
    framework_off_heap_memory = 128

    # should be some simple maths but seems to always run into other constraints
    remaining_memory = (
        total_flink_memory
        - (network_memory + managed_memory + framework_heap_memory + framework_off_heap_memory)
    )

    # calculate dynamic values
    return {
        "total_flink": int(total_flink_memory),
        "task_heap": int(remaining_memory * 0.90),
        "task_off_heap": int(remaining_memory * 0.10),
        "task_memory_managed_fraction": managed_memory_ratio
    }


resource_profile_choice = os.environ.get("RESOURCE_PROFILE", "large")
task_manager_process_memory_map = {
    "small": 7168,
    "medium": 10240,
    "large": 15360,
    "xlarge": 20480,
}
if resource_profile_choice not in list(task_manager_process_memory_map.keys()):
    raise ValueError(
        f"Your 'resource_profile' choice '{resource_profile_choice}' was not one "
        f"of '{list(task_manager_process_memory_map.keys())}'"
    )

task_manager_resources = calc_task_manager_resources(
    task_manager_process_memory_map[resource_profile_choice]
)
print(f"[ CALCULATED TASK MANAGER RESOURCES ]: {task_manager_resources}")


BUCKET_PREFIX = s3_uri
c.Bake.prune = bool(int(os.environ.get("PRUNE_OPTION", True)))
c.Bake.container_image = "apache/beam_python3.11_sdk:2.52.0"
c.Bake.bakery_class = "pangeo_forge_runner.bakery.flink.FlinkOperatorBakery"
c.Bake.feedstock_subdir = os.environ.get("FEEDSTOCK_SUBDIR")

c.FlinkOperatorBakery.parallelism = int(os.environ.get("PARALLELISM_OPTION", 1))
c.FlinkOperatorBakery.enable_job_archiving = True
c.FlinkOperatorBakery.flink_version = "1.16"
c.FlinkOperatorBakery.job_manager_resources = {"memory": "1536m", "cpu": 0.3}
c.FlinkOperatorBakery.task_manager_resources = {
    "memory": f"{task_manager_process_memory_map[resource_profile_choice]}m",
    "cpu": 0.3
}
c.FlinkOperatorBakery.flink_configuration = {
    "taskmanager.numberOfTaskSlots": "1",
    "taskmanager.memory.flink.size": f"{task_manager_resources['total_flink']}m",
    "taskmanager.memory.task.heap.size": f"{task_manager_resources['task_heap']}m",
    "taskmanager.memory.task.off-heap.size": f"{task_manager_resources['task_off_heap']}m",
    "taskmanager.memory.managed.fraction": f"{task_manager_resources['task_memory_managed_fraction']}"
}

c.TargetStorage.fsspec_class = "s3fs.S3FileSystem"
c.TargetStorage.root_path = f"{BUCKET_PREFIX}/{{job_name}}/output"
c.TargetStorage.fsspec_args = {
    "key": os.environ.get("S3_DEFAULT_AWS_ACCESS_KEY_ID"),
    "secret": os.environ.get("S3_DEFAULT_AWS_SECRET_ACCESS_KEY"),
    "token": os.environ.get("S3_DEFAULT_AWS_SESSION_TOKEN"),
    "anon": False,
    "client_kwargs": {"region_name": "us-west-2"},
}

c.InputCacheStorage.fsspec_class = c.TargetStorage.fsspec_class
c.InputCacheStorage.fsspec_args = c.TargetStorage.fsspec_args
c.InputCacheStorage.root_path = f"{BUCKET_PREFIX}/cache/"

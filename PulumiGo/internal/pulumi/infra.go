package pulumi

import (
	"fmt"

	pulumisdk "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func DeployInfrastructure() error {
	return pulumisdk.RunErr(func(ctx *pulumisdk.Context) error {
		ctx.Export("message", pulumisdk.String("Hello from PulumiGo!"))
		fmt.Println("✅ Pulumi stack deployed.")
		return nil
	})
}
